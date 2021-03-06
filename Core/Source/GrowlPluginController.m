//
//  GrowlPluginController.m
//  Growl
//
//  Created by Nelson Elhage on 8/25/04.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "GrowlPluginController.h"
#import "GrowlPreferencesController.h"
#import "GrowlDefinesInternal.h"

#import "GrowlPathUtilities.h"
#import "GrowlTicketDatabase.h"

#import "NSSetAdditions.h"
#import "NSWorkspaceAdditions.h"
#import "GrowlWebKitPluginHandler.h"
#import "GrowlApplicationController.h"
#import "GrowlMenu.h"
#import "GrowlWebKitDisplayPlugin.h"
#import <GrowlPlugins/GrowlDisplayPlugin.h>
#import <GrowlPlugins/GrowlActionPlugin.h>


#ifndef __has_feature      // Optional.
#define __has_feature(x) 0 // Compatibility with non-clang compilers.
#endif

#ifndef NS_CONSUMED
#if __has_feature(attribute_ns_consumed)
#define NS_CONSUMED __attribute__((ns_consumed))
#else
#define NS_CONSUMED
#endif
#endif

@interface GrowlPluginController (PRIVATE)
- (void) registerDefaultPluginHandlers;
- (void) findAndLoadPluginsInDirectory:(NSString *)dir;
- (void) pluginInstalledSelector:(NSModalResponse)returnCode contextInfo:(void *) contextInfo;
- (void) pluginExistsSelector:(NSModalResponse)returnCode contextInfo:(void *) contextInfo;
- (BOOL) hasNativeArchitecture:(NSString *)filename;
@end

@interface WebCoreCache
+ (void) empty;
@end

//for use as CFSetCallBacks.equal
static Boolean caseInsensitiveStringComparator(const void *value1, const void *value2);
//for use as CFSetCallBacks.hash
static CFHashCode passthroughStringHash(const void *value);
//for use on array of matching plug-in handlers in -openPluginAtPath:
NSInteger comparePluginHandlerRegistrationOrder(id a, id b, void *context);

static void eventStreamCallback(ConstFSEventStreamRef eventStream, void *clientCallBackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIDs[]);

#pragma mark -

NSString *GrowlPluginControllerWillAddPluginHandlerNotification = @"GrowlPluginControllerWillAddPluginHandlerNotification";
NSString *GrowlPluginControllerDidAddPluginHandlerNotification = @"GrowlPluginControllerDidAddPluginHandlerNotification";
NSString *GrowlPluginControllerWillRemovePluginHandlerNotification = @"GrowlPluginControllerWillRemovePluginHandlerNotification";
NSString *GrowlPluginControllerDidRemovePluginHandlerNotification = @"GrowlPluginControllerDidRemovePluginHandlerNotification";

//Info.plist keys for plug-in bundles.
NSString *GrowlPluginInfoKeyName              = @"CFBundleName";
NSString *GrowlPluginInfoKeyAuthor            = @"GrowlPluginAuthor";
NSString *GrowlPluginInfoKeyVersion           = @"CFBundleVersion";
NSString *GrowlPluginInfoKeyDescription       = @"GrowlPluginDescription";
//keys in plug-in description dictionaries (also includes the above).
NSString *GrowlPluginInfoKeyBundle            = @"GrowlPluginBundle";
NSString *GrowlPluginInfoKeyTypes             = @"GrowlPluginType";
NSString *GrowlPluginInfoKeyPath              = @"GrowlPluginPath";
NSString *GrowlPluginInfoKeyHumanReadableName = @"GrowlPluginHumanReadableName";
NSString *GrowlPluginInfoKeyIdentifier        = @"GrowlPluginIdentifier";
NSString *GrowlPluginInfoKeyInstance          = @"GrowlPluginInstance";

/*******************************************************************************
 *  _____ ___  ____   ___
 * |_   _/ _ \|  _ \ / _ \
 *   | || | | | | | | | | |
 *   | || |_| | |_| | |_| |
 *   |_| \___/|____/ \___/
 *
 *******************************************************************************
 *
 * 	-	Use identifier strings for all loaded plug-ins (simpler than using
 *		human-readable names) (DONE though this will probably only be used for
 *		storage of plug-in prefs)
 *	-	Use plug-in dictionaries (DONE)
 *	-	Write the built-in plug-in handler (DONE)
 *	-	Add a WebKit plug-in handler (jkp)
 *	-	Better localize human-readable names
 */

@interface GrowlPluginController ()

- (void) handleFileSystemEventFromStream:(ConstFSEventStreamRef)eventStream
							  eventPaths:(NSArray *)paths
							  eventFlags:(const FSEventStreamEventFlags [])eventFlags
								eventIDs:(const FSEventStreamEventId [])eventIDs;

@end

@implementation GrowlPluginController

@synthesize pluginsByBundleIdentifier;

+ (GrowlPluginController *) sharedController {
	static GrowlPluginController *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        [instance performSelector:@selector(loadPlugins) withObject:nil afterDelay:0.0]; //defer initalization
	 });
    return instance;
}

- (instancetype) init {
	if ((self = [super init])) {
		bundlesToLazilyInstantiateAnInstanceFrom = [[NSMutableSet alloc] init];

		pluginsByIdentifier         = [[NSMutableDictionary alloc] init];
		pluginsByBundleIdentifier   = [[NSMutableDictionary alloc] init];
		pluginIdentifiersByPath     = [[NSMutableDictionary alloc] init];
		pluginIdentifiersByBundle   = [NSMapTable strongToStrongObjectsMapTable];
		pluginIdentifiersByInstance = [NSMapTable strongToStrongObjectsMapTable];

		pluginsByName     = [[NSMutableDictionary alloc] init];
		pluginsByAuthor   = [[NSMutableDictionary alloc] init];
		pluginsByVersion  = [[NSMutableDictionary alloc] init];
		pluginsByFilename = [[NSMutableDictionary alloc] init];
		pluginsByType     = [[NSMutableDictionary alloc] init];
		pluginHumanReadableNames = [[NSCountedSet alloc] init];


		allPluginHandlers = [[NSMutableArray alloc] init];
		pluginHandlers  = [[NSMutableDictionary alloc] init];
		handlersForPlugins = [NSMapTable strongToStrongObjectsMapTable];

		displayPlugins = [[NSMutableArray alloc] init];
		disabledPlugins = [[NSMutableSet alloc] init];

		[self registerDefaultPluginHandlers];

		enum { builtInTypesCount = 4U };
		/*NSString *builtInTypesArray[builtInTypesCount] = {
			GROWL_STYLE_EXTENSION,
			GROWL_VIEW_EXTENSION,
			GROWL_PATHWAY_EXTENSION,
			GROWL_PLUGIN_EXTENSION,
		};*/
        void * array[builtInTypesCount] = {
            GROWL_STYLE_EXTENSION,
            GROWL_VIEW_EXTENSION,
            GROWL_PATHWAY_EXTENSION,
            GROWL_PLUGIN_EXTENSION,
        };
        
		CFSetCallBacks callbacks = kCFCopyStringSetCallBacks;
		callbacks.equal = caseInsensitiveStringComparator;
		callbacks.hash = passthroughStringHash;
		builtInTypes = (NSSet *)CFBridgingRelease(CFSetCreate(kCFAllocatorDefault,
		                                    (const void **)array,
		                                    builtInTypesCount,
		                                    &callbacks));
	}

	return self;
}

- (void) dealloc {






	FSEventStreamInvalidate(pluginsDirectoryEventStream);
	CFRelease(pluginsDirectoryEventStream);

}

#pragma mark -

- (void) loadPlugins {
    //Find plugins inside GHA itself first
    [self findAndLoadPluginsInDirectory:[NSBundle mainBundle].builtInPlugInsPath];
    
    /* Then find plug-ins in Library/Application Support/Growl/Plugins directories. This allows GHA to override externally installed plugins,
     * which are fairly common as some 3rd party plugins have been rolled into the Growl distribution.
     */
    NSArray *libraries = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSMutableArray *pluginsDirectoryPaths = [NSMutableArray arrayWithCapacity:libraries.count];
    NSFileManager *mgr = [NSFileManager defaultManager];
    for (__strong NSString *dir in libraries) {
        dir = [dir stringByAppendingPathComponent:@"Application Support/Growl/Plugins"];
        BOOL isDir = NO;
        if ([mgr fileExistsAtPath:dir isDirectory:&isDir] && isDir) {
            [self findAndLoadPluginsInDirectory:dir];
            [pluginsDirectoryPaths addObject:dir];
        }
    }
    
    pluginsDirectoryEventStreamContext = (struct FSEventStreamContext){
        .version = 0,
        .info = (__bridge void *)self,
        .copyDescription = (CFAllocatorCopyDescriptionCallBack)CFCopyDescription,
    };
    pluginsDirectoryEventStream = FSEventStreamCreate(kCFAllocatorDefault,
                                                      eventStreamCallback,
                                                      &pluginsDirectoryEventStreamContext,
                                                      (__bridge CFArrayRef)pluginsDirectoryPaths,
                                                      kFSEventStreamEventIdSinceNow,
                                                      /*latency*/ 1.0,
                                                      kFSEventStreamCreateFlagUseCFTypes);
    
    FSEventStreamScheduleWithRunLoop(pluginsDirectoryEventStream, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
    FSEventStreamStart(pluginsDirectoryEventStream);
}

- (void) registerDefaultPluginHandlers {
	//register ourselves for display plug-ins (non-WebKit), pathway plug-ins, and functional plug-ins.
	NSSet *types = [[NSSet alloc] initWithObjects:
		//display plug-ins
		GROWL_VIEW_EXTENSION,
		NSFileTypeForHFSTypeCode(FOUR_CHAR_CODE('DISP')),
		//pathway plug-ins
		GROWL_PATHWAY_EXTENSION,
		NSFileTypeForHFSTypeCode(FOUR_CHAR_CODE('PWAY')),
		//generic functional plug-ins
		GROWL_PLUGIN_EXTENSION,
		NSFileTypeForHFSTypeCode(FOUR_CHAR_CODE('GEXT')),
		nil];

	[self addPluginHandler:self forPluginTypes:types];


	[self addPluginHandler:[GrowlWebKitPluginHandler sharedInstance] forPluginTypes:[NSSet setWithObject:GROWL_STYLE_EXTENSION]];
}

#pragma mark -
#pragma mark GrowlPluginHandler protocol conformance

//the method that dispatches incoming plug-ins to plug-in handlers is -dispatchPluginAtPath:.
//this is for handling plug-ins of the built-in types.
- (BOOL)loadPluginWithBundle:(NSBundle *)bundle {
	[self addPluginInstance:nil fromBundle:bundle];

	return YES;
}

#pragma mark -
#pragma mark Plugin-handler handling

- (void) addPluginHandler:(id <GrowlPluginHandler>)handler forPluginTypes:(NSSet *)types {
	NSParameterAssert(handler != nil);
	NSParameterAssert(types != nil);

	if (!types.count) {
		NSLog(@"Warning: -[%@ addPluginHandler:forPluginTypes:] called with an empty set of file types. This may be indicative of a bug in Growl or a plug-in. The handler was %@.", [self class], handler);
	} else {
		//make sure nobody tries to register a plug-in handler for a built-in type.
		if (builtInTypes) {
			NSMutableSet *builtInMutable = [builtInTypes mutableCopy];
			[builtInMutable intersectSet:types];

			//the intersection must be empty; if it isn't, at least one of the types for which this handler is attempting to register is a built-in type.
			NSAssert2([builtInMutable count] == 0U, @"Something attempted to register a plug-in handler for one or more reserved file types (%@). The handler was %@.", builtInMutable, handler);

		}

		for (__strong NSString *type in types) {
			//normalise: strip leading ., if any.
			NSUInteger i = 0U, len = type.length;
			for (; i < len; ++i) {
				if ([type characterAtIndex:i] != '.')
					break;
			}
			NSAssert2(i < len, @"Something tried to register a plug-in handler for a file type consisting entirely of %u full stops ('.'). The handler was %@.", len, handler);
			if (i)
				type = [type substringFromIndex:i];

			NSMutableArray *handlers = pluginHandlers[type];
			if (!handlers) {
				handlers = [[NSMutableArray alloc] initWithCapacity:1U];
				pluginHandlers[type] = handlers;
			}
			[handlers addObject:handler];
		}

		[allPluginHandlers addObject:handler];

		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		NSDictionary *notificationUserInfo = @{@"GrowlPluginHandler": handler};

		[nc postNotificationName:GrowlPluginControllerWillAddPluginHandlerNotification
						  object:self
						userInfo:notificationUserInfo];

		[allPluginHandlers addObject:handler];

		//add the handler as an observer for various notifications.
		if ([handler respondsToSelector:@selector(growlPluginControllerWillAddPluginHandler:)]) {
			[nc addObserver:handler
				   selector:@selector(growlPluginControllerWillAddPluginHandler:)
					   name:GrowlPluginControllerWillAddPluginHandlerNotification
					 object:self];
		}
		if ([handler respondsToSelector:@selector(growlPluginControllerDidAddPluginHandler:)]) {
			[nc addObserver:handler
				   selector:@selector(growlPluginControllerDidAddPluginHandler:)
					   name:GrowlPluginControllerDidAddPluginHandlerNotification
					 object:self];
		}
		if ([handler respondsToSelector:@selector(growlPluginControllerWillRemovePluginHandler:)]) {
			[nc addObserver:handler
				   selector:@selector(growlPluginControllerWillRemovePluginHandler:)
					   name:GrowlPluginControllerWillRemovePluginHandlerNotification
					 object:self];
		}
		if ([handler respondsToSelector:@selector(growlPluginControllerDidRemovePluginHandler:)]) {
			[nc addObserver:handler
				   selector:@selector(growlPluginControllerDidRemovePluginHandler:)
					   name:GrowlPluginControllerDidRemovePluginHandlerNotification
					 object:self];
		}

		[nc postNotificationName:GrowlPluginControllerDidAddPluginHandlerNotification
						  object:self
						userInfo:notificationUserInfo];
	}
}

- (void) removePluginHandler:(id <GrowlPluginHandler>)handler forPluginTypes:(NSSet *)extensions {
	NSParameterAssert(handler != nil);

	[allPluginHandlers removeObjectIdenticalTo:handler];

	if (!extensions)
		extensions = (NSSet *)[pluginHandlers allKeysForObject:handler];

	for (NSString *ext in extensions) {
		NSMutableArray *handlers = pluginHandlers[ext];
		if (handlers) {
			NSUInteger idx = [handlers indexOfObjectIdenticalTo:handler];
			if (idx != NSNotFound)
				[handlers removeObjectAtIndex:idx];
		}
	}
}

- (NSArray *) allPluginHandlers {
	return [allPluginHandlers copy];
}

#pragma mark -

//Private method.
//This creates and returns a hash table that uses the object's pointer for the hash, instead of sending it a -hash message. This enables us to mutate the object without disturbing its hash.
- (NSHashTable *) makeHashTableWithObject:(NSObject *)obj {
	NSHashTable *hashTable = [NSHashTable hashTableWithOptions:NSHashTableStrongMemory | NSHashTableObjectPointerPersonality];
	[hashTable addObject:obj];
	return hashTable;
}

//private method.
- (NSDictionary *) addPluginInstance:(GrowlPlugin *)plugin fromPath:(NSString *)path bundle:(NSBundle *)bundle {
	//If we're passed a bundle, refuse to load it if we've already loaded a different bundle with the same identifier, instead returning whatever dictionary we already have.
	NSMutableDictionary *pluginDict = nil;
	NSString *bundleIdentifier = bundle.bundleIdentifier;
	if (bundleIdentifier) {
		pluginDict = pluginsByBundleIdentifier[bundleIdentifier];
		if (pluginDict && (bundle != pluginDict.pluginBundle))
			return pluginDict;
	}
	
	NSString *frameworkVersion = [bundle objectForInfoDictionaryKey:@"GrowlPluginsFrameworkVersion"];
	//Check our framework version is valid, for 2.0, we only need a framework version
	//We don't count WebKit plugin bundles
	if((!frameworkVersion || [frameworkVersion isEqualToString:@""]) && ![plugin isKindOfClass:[GrowlWebKitDisplayPlugin class]]){
		if(![disabledPlugins containsObject:bundle.bundlePath]){
			NSLog(@"Adding %@ to disabled plug-ins because it is incompatible with Growl version 2.0 and later", [bundle objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey]);
			[disabledPlugins addObject:bundle.bundlePath];
		}
		return pluginDict;
	}
   
	//Look up the identifier for the plugin. We try to look up the identifier by the instance, by the bundle; and by the pathname, in that order.
	NSString *identifier = nil;
	if (plugin)
		identifier = [pluginIdentifiersByInstance objectForKey:plugin];
	else if (bundle)
		identifier = [pluginIdentifiersByBundle   objectForKey:bundle];
	else if (path)
		identifier = pluginIdentifiersByPath[path];
   
	/* If we have an identifier, look up the plug-in dictionary.
	 * If we have a plug-in dictionary but no instance (the identifier was retrieved by bundle or by path), attempt to retrieve the instance from the dictionary.
	 */
	pluginDict = identifier ? pluginsByIdentifier[identifier] : nil;
	if (pluginDict && !plugin)
		plugin = pluginDict.pluginInstance;
   
	//Assert that we have an instance OR a bundle. We need at least one to proceed.
	NSAssert1(plugin || bundle, @"Cannot load plug-ins lazily without a bundle (path: %@)", path);
   
	//Get the plug-in's name, author, and version. All three come from the plug-in instance if it exists and responds to -name/-author/-version; if both requirements are not satisfied, the information is retrieved from the bundle's Info.plist.
	NSString *name    = plugin ? ([plugin respondsToSelector:@selector(name)] ? plugin.name : [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey])
   : [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
	NSString *author  = plugin ? ([plugin respondsToSelector:@selector(author)] ? plugin.author : [bundle objectForInfoDictionaryKey:GrowlPluginInfoKeyAuthor])
   : [bundle objectForInfoDictionaryKey:GrowlPluginInfoKeyAuthor];
	NSString *version = plugin ? ([plugin respondsToSelector:@selector(version)] ? plugin.version : [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey])
   : [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
   
	//If we don't have a pathname, get it as the bundle's pathname.
	if (!path)
		path = bundle.bundlePath;
	NSString *extension = path.pathExtension;
	NSString *fileTypeString = nil;
	OSType fileType = 0;
   
	//Assert that we have a name, author, and version. (We got the path first so we can use it in the assertion message.)
	NSAssert5((name != nil) && (author != nil) && (version != nil),
             @"Cannot load plug-in at path %@ (plug-in instance's class: %@). One of these is (null), but they must all not be:\n"
             @"\t"@"   name: %@\n"
             @"\t"@" author: %@\n"
             @"\t"@"version: %@\n",
             path, [plugin class], name, author, version);
   
	//In case we got the names from the plug-in instance and it gave us a mutable string for some reason, make copies for ourselves.
	//Note: This isn't a performance hit when the strings are immutable. -copy = -retain in that situation. Thanks, Apple!
	name    = [name    copy];
	author  = [author  copy];
	version = [version copy];
   
	//If we don't have an identifier yet, forge it.
	if (!identifier)
		identifier = [NSString stringWithFormat:@"Name: %@ Author: %@ Path: %@", name, author, path];
   
	//If we don't have an instance but we do have a bundle, see if we've previously queued the bundle for lazy instantiation.
	if (!plugin && bundle) {
		if (![bundlesToLazilyInstantiateAnInstanceFrom containsObject:bundle]) {
			//We haven't previously queued it: Queue it.
			[bundlesToLazilyInstantiateAnInstanceFrom addObject:bundle];
		} else if (![disabledPlugins containsObject:path]) {
			//We have: This is our cue to instantiate it.
			plugin = [[bundle.principalClass alloc] init];
			//Dequeue it, because we don't want to hit this branch again for this plug-in.
			[bundlesToLazilyInstantiateAnInstanceFrom removeObject:bundle];
			if (plugin) {
				//Stash the plug-in instance in the plug-in dictionary. This retains the instance and means that we'll never hit the lazy-instantiation machinery again (because plugin will be non-nil).
				pluginDict[GrowlPluginInfoKeyInstance] = plugin;
			} else {
				//Couldn't instantiate the plug-in, perhaps because of an architecture mismatch. Put it into disabled plug-ins.
				NSLog(@"Adding %@ to disabled plug-ins because we could not instantiate its class %@ (from bundle %@)", name, NSStringFromClass(bundle.principalClass), bundle);
            [self willChangeValueForKey:@"disabledPluginsPresent"];
            [disabledPlugins addObject:bundle.bundlePath];
            [self didChangeValueForKey:@"disabledPluginsPresent"];
			}
		}
	}
   
	/*If we don't actually have a plug-in dictionary, create it.
	 *Elements of a plug-in dictionary:
	 *	Plug-in name
	 *	Author
	 *	Version
	 *	Pathname
	 *	Identifier
	 *	Instance (later; see above lazy-instantiation code)
	 *	Plug-in's HFS type and filename extension (combined in a set)
	 */
	BOOL pluginDictIsNew = !pluginDict;
	if (!pluginDict) {
		pluginDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                    name,                 GrowlPluginInfoKeyName,
                    author,               GrowlPluginInfoKeyAuthor,
                    version,              GrowlPluginInfoKeyVersion,
                    path,                 GrowlPluginInfoKeyPath,
                    identifier,           GrowlPluginInfoKeyIdentifier,
                    nil];
		NSString *description = ([plugin respondsToSelector:@selector(pluginDescription)] ? plugin.pluginDescription : nil);
		
		if (description)
			pluginDict[GrowlPluginInfoKeyDescription] = description;
      
		[[NSWorkspace sharedWorkspace] getFileType:&fileTypeString forFile:path];
		fileType = fileTypeString ? NSHFSTypeCodeFromFileType(fileTypeString) : 0;
      
		//Record the file types (HFS and filename extension) that the plug-in possessed at this time. These help determine what kind of plug-in it is (e.g. .growlView = custom view; .growlStyle = WebKit display).
		NSSet *types = nil;
		if (extension) {
			if (fileType)
				types = [NSSet setWithObjects:extension, fileTypeString, nil];
			else
				types = [NSSet setWithObject:extension];
		} else if (fileType)
			types = [NSSet setWithObject:fileTypeString];
      
		if (types)
			pluginDict[GrowlPluginInfoKeyTypes] = types;
	}
   
	//We have a bundle. If no previous bundle was stored in the plug-in dictionary (why wouldn't there be?), store this bundle there. Also register the identifier as being the one for this bundle.
	if (bundle) {
		if (!pluginDict[GrowlPluginInfoKeyBundle])
			pluginDict[GrowlPluginInfoKeyBundle] = bundle;
		[pluginIdentifiersByBundle setObject:identifier forKey:bundle];
	}
	//We have an instance. If no previous instance was stored in the plug-in dictionary (why wouldn't there be?), store this instance there. Also register the identifier as being the one for this instance.
	if (plugin) {
		if (!pluginDict[GrowlPluginInfoKeyInstance])
			pluginDict[GrowlPluginInfoKeyInstance] = plugin;
		[pluginIdentifiersByInstance setObject:identifier forKey:plugin];
	}
   
	//If we just created the dictionary (and got done filling it out), start storing it in places.
	if (pluginDictIsNew) {
		pluginsByIdentifier[identifier] = pluginDict;
		pluginIdentifiersByPath[path] = identifier;
      
#define ADD_TO_DICT(dictName, key, value)                                          \
do {                                                                        \
NSHashTable *plugins = [dictName objectForKey:key];                     \
if (plugins)                                                              \
[plugins addObject:value];                                             \
else                                                                        \
[dictName setObject:[self makeHashTableWithObject:value] forKey:key];    \
} while(0)
		ADD_TO_DICT(pluginsByName,     name,                     pluginDict);
		ADD_TO_DICT(pluginsByAuthor,   author,                   pluginDict);
		ADD_TO_DICT(pluginsByVersion,  version,                  pluginDict);
		ADD_TO_DICT(pluginsByFilename, [path lastPathComponent], pluginDict);
      
		ADD_TO_DICT(pluginsByType, extension, pluginDict);
		ADD_TO_DICT(pluginsByType, fileTypeString,  pluginDict);
#undef ADD_TO_DICT
	}
   
	//Release our copies.
   
	//Invalidate non-display plug-in caches.
   cache_allPlugins = nil;
   cache_allPluginsArray = nil;
   cache_registeredPluginTypes = nil;
   cache_registeredPluginNames = nil;
   cache_registeredPluginNamesArray = nil;
   
	//Special handling if this plug-in is a display.
	if ([self pluginWithDictionaryIsDisplayPlugin:pluginDict]) {
		//If it doesn't conform to GrowlDispatchNotificationProtocol, it's old. Add it as a disabled plug-in.
		if(plugin && ![plugin conformsToProtocol:@protocol(GrowlDispatchNotificationProtocol)]) {
         NSLog(@"Adding %@ to disabled plug-ins because %@ is incompatible with Growl version 2.0 and later", bundle.bundlePath, plugin);
         [self willChangeValueForKey:@"disabledPluginsPresent"];
         [disabledPlugins addObject:bundle.bundlePath];
         [self didChangeValueForKey:@"disabledPluginsPresent"];
      }
      
      NSUInteger index = [displayPlugins indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
         return [identifier caseInsensitiveCompare:[obj valueForKey:GrowlPluginInfoKeyIdentifier]] == NSOrderedSame;
      }];
      if(![disabledPlugins containsObject:pluginDict[GrowlPluginInfoKeyPath]]){
         if(index == NSNotFound){
            [displayPlugins addObject:pluginDict];
         }else{
            displayPlugins[index] = pluginDict;
         }
      }else{
         //We need to remove this, we tried to lazy instantiate it and failed
         if(index != NSNotFound){
            NSLog(@"Removing plugin %@ from display plugins list", pluginDict[GrowlPluginInfoKeyName]);
            [displayPlugins removeObjectAtIndex:index];
         }
      }
		
		//Invalidate display plug-in cache.
		[self willChangeValueForKey:@"displayPlugins"];
      cache_displayPlugins = nil;
      [self didChangeValueForKey:@"displayPlugins"];
	}
   
	//Store the bundle identifier so we know we've loaded it.
	if (bundleIdentifier) {
		pluginsByBundleIdentifier[bundleIdentifier] = pluginDict;
	}
   
	return pluginDict;
}

- (NSArray *) disabledPlugins {
	return disabledPlugins.allObjects;
}

- (BOOL) disabledPluginsPresent {
	return (disabledPlugins.count > 0);
}

- (NSDictionary *) addPluginInstance:(GrowlPlugin *)plugin fromBundle:(NSBundle *)bundle {
	return [self addPluginInstance:plugin fromPath:nil bundle:bundle];
}
- (NSDictionary *) addPluginInstance:(GrowlPlugin *)plugin fromPath:(NSString *)path {
	return [self addPluginInstance:plugin fromPath:path bundle:nil];
}

#pragma mark -

- (NSSet *) registeredPluginTypes {
	if (!cache_registeredPluginTypes)
		cache_registeredPluginTypes = [[NSSet alloc] initWithArray:pluginHandlers.allKeys];

	return cache_registeredPluginTypes;
}

- (NSSet *) registeredPluginNames {
	if (!cache_registeredPluginNames)
		cache_registeredPluginNames = [[NSSet alloc] initWithArray:self.registeredPluginNamesArray];
	return cache_registeredPluginNames;
}

- (NSArray *) registeredPluginNamesArray {
	if (!cache_registeredPluginNamesArray) {
		cache_registeredPluginNamesArray = [pluginsByIdentifier.allValues valueForKey:GrowlPluginInfoKeyName];
	}
	return cache_registeredPluginNamesArray;
}

#pragma mark -

- (NSArray *) allPluginDictionariesArray {
	if (!cache_allPluginsArray)
		cache_allPluginsArray = [pluginsByIdentifier.allValues copy];
	return cache_allPluginsArray;
}
- (NSSet *) allPluginDictionaries {
	if (!cache_allPlugins)
		cache_allPlugins = [[NSMutableSet alloc] initWithArray:self.allPluginDictionariesArray];
	return cache_allPlugins;
}
- (NSArray *) allPluginInstances {
	if (!cache_allPluginInstances)
		cache_allPluginInstances = [self.allPluginDictionaries valueForKey:GrowlPluginInfoKeyInstance];
	return cache_allPluginInstances;
}

- (NSSet *) pluginDictionariesWithName:(NSString *)name author:(NSString *)author version:(NSString *)version type:(NSString *)type {
	NSMutableSet *matches = [self.allPluginDictionaries mutableCopy];

	if (matches.count) {
		if (name)
			[matches intersectSet:[pluginsByName[name] setRepresentation]];
		if (author)
			[matches intersectSet:[pluginsByAuthor[author] setRepresentation]];
		if (version)
			[matches intersectSet:[pluginsByVersion[version] setRepresentation]];
		if (type)
			[matches intersectSet:[pluginsByType[type] setRepresentation]];
	}

	return matches;
}
- (NSDictionary *) pluginDictionaryWithName:(NSString *)name author:(NSString *)author version:(NSString *)version type:(NSString *)type {
	NSSet *matches = [self pluginDictionariesWithName:name author:author version:version type:type];
	if (matches.count == 1U)
		return [matches anyObject];
	else
		return nil;
}
- (NSDictionary *) pluginDictionaryWithName:(NSString *)name {
	return [self pluginDictionaryWithName:name author:nil version:nil type:nil];
}
- (GrowlPlugin *) pluginInstanceWithName:(NSString *)name author:(NSString *)author version:(NSString *)version type:(NSString *)type {
	NSDictionary *pluginDict = [self pluginDictionaryWithName:name author:author version:version type:type];
	GrowlPlugin *instance = pluginDict.pluginInstance;
	if (!instance) {
		NSBundle *bundle = pluginDict.pluginBundle;
		if (bundle) {
			[self addPluginInstance:nil fromBundle:bundle]; //causes instantiation
			instance = pluginDict.pluginInstance;
		}
	}
	return instance;
}
- (GrowlPlugin *) pluginInstanceWithName:(NSString *)name {
	return [self pluginInstanceWithName:name author:nil version:nil type:nil];
}

#pragma mark -

- (NSString *) humanReadableNameForPluginWithDictionary:(NSDictionary *)pluginDict {
	NSString *humanReadableName = pluginDict.pluginHumanReadableName;

	if (!humanReadableName) {
		NSString *name = pluginDict.pluginName;
		if ([pluginsByName[name] count] == 1U)
			humanReadableName = name;
		else {
			NSString *author = pluginDict.pluginAuthor;
			if ([pluginsByAuthor[author] count] == 1U)
				humanReadableName = [NSString stringWithFormat:@"%@ (by %@)", name, author]; //XXX LOCALIZEME
			else {
				NSString *filename = pluginDict.pluginPath.lastPathComponent;
				if ([pluginsByFilename[filename] count] == 1U)
					humanReadableName = [NSString stringWithFormat:@"%@ (filename %@)", name, filename]; //XXX LOCALIZEME
				else {
					humanReadableName = [NSString stringWithFormat:@"%@ (by %@, filename %@)", name, author, filename]; //XXX LOCALIZEME
					NSUInteger count = [pluginHumanReadableNames countForObject:humanReadableName];
					[pluginHumanReadableNames addObject:humanReadableName];
					if (count > 1U)
						humanReadableName = [NSString stringWithFormat:@"%@ %lu", humanReadableName, count];
				}
			}
		}

		if ([pluginDict isKindOfClass:[NSMutableDictionary class]]) {
			//save the name for later retrieval.
			((NSMutableDictionary *)pluginDict)[GrowlPluginInfoKeyHumanReadableName] = humanReadableName;
		}
	}

	return humanReadableName;
}

- (BOOL) pluginWithDictionaryIsDisplayPlugin:(NSDictionary *)pluginDict {
	GrowlPlugin *instance = pluginDict.pluginInstance;
	if (instance)
		return [instance isKindOfClass:[GrowlDisplayPlugin class]] || [instance isKindOfClass:[GrowlActionPlugin class]];
	else {
		NSBundle *bundle = pluginDict.pluginBundle;
		NSAssert1(bundle, @"no instance or bundle in plug-in dictionary! description of dictionary follows\n%@", pluginDict);
		NSString *ext = bundle.bundlePath.pathExtension;
		return [ext isEqualToString:GROWL_VIEW_EXTENSION] || [ext isEqualToString:GROWL_STYLE_EXTENSION];
	}
}

#pragma mark -

- (NSArray *) displayPlugins {
	if (!cache_displayPlugins)
		cache_displayPlugins = [[NSArray alloc] initWithArray:displayPlugins];
	return cache_displayPlugins;
}

#pragma mark -

- (NSSet *) displayPluginDictionariesWithName:(NSString *)name author:(NSString *)author version:(NSString *)version type:(NSString *)type {
	NSMutableSet *matches = (NSMutableSet *)[self pluginDictionariesWithName:name
																	  author:author
																	 version:version
																		type:type];

	NSSet *copyForIteration = [matches copy];
	for (NSDictionary *pluginDict in copyForIteration) {
		if (![self pluginWithDictionaryIsDisplayPlugin:pluginDict])
			[matches removeObject:pluginDict];
	}

	return matches;
}

- (NSDictionary *) displayPluginDictionaryWithName:(NSString *)name author:(NSString *)author version:(NSString *)version type:(NSString *)type {
	NSSet *matches = [self displayPluginDictionariesWithName:name
													  author:author
													 version:version
														type:type];
	if (matches.count == 1U)
		return [matches anyObject];
	else
		return nil;
}

- (GrowlDisplayPlugin *) displayPluginInstanceWithName:(NSString *)name author:(NSString *)author version:(NSString *)version type:(NSString *)type {
	GrowlPlugin *plugin = [self pluginInstanceWithName:name author:author version:version type:type];
	if (plugin && [plugin isKindOfClass:[GrowlDisplayPlugin class]])
		return (GrowlDisplayPlugin *)plugin;
	else
		return nil;
}

#pragma mark -
#pragma mark Finding and using installed plug-ins

- (void) findAndLoadPluginsInDirectory:(NSString *)dir {
	NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:dir];
	NSString *file;
	while ((file = [enumerator nextObject])) {
		NSString *fullPath = [dir stringByAppendingPathComponent:file];

		NSString *pathExtension = file.pathExtension;
		NSString *fileType;
		[[NSWorkspace sharedWorkspace] getFileType:&fileType forFile:fullPath];
		if (pluginHandlers[pathExtension] || (fileType && pluginHandlers[fileType])) {
			[self dispatchPluginAtPath:fullPath];
			[enumerator skipDescendents];
		}
	}
}

- (void) dispatchPluginAtPath:(NSString *)path {
	//get all the relevant handlers, by extension and by type.
	NSArray *handlersByExtension = pluginHandlers[path.pathExtension];
	NSString *fileType;
	[[NSWorkspace sharedWorkspace] getFileType:&fileType forFile:path];
	NSArray *handlersByType      = pluginHandlers[fileType];

	//strip duplicates by making a set from both arrays.
	NSMutableSet *allMatchingHandlersSet = handlersByExtension ? [NSMutableSet setWithArray:handlersByExtension] : [NSMutableSet set];
	if (handlersByType)
		[allMatchingHandlersSet unionSet:[NSSet setWithArray:handlersByType]];

	NSMutableArray *allMatchingHandlers = [allMatchingHandlersSet.allObjects mutableCopy];
	[allMatchingHandlers sortUsingFunction:comparePluginHandlerRegistrationOrder context:(__bridge void *)(self)];

	NSBundle *pluginBundle = [[NSBundle alloc] initWithPath:path];

	for (id <GrowlPluginHandler> handler in allMatchingHandlers) {
		BOOL success = NO;
		if (pluginBundle && [handler respondsToSelector:@selector(loadPluginWithBundle:)]) {
			success = (NSUInteger)[handler performSelector:@selector(loadPluginWithBundle:) withObject:pluginBundle];
			if (!success)
				NSLog(@"%@: Handler %@ could not load plug-in with bundle %@", [self class], handler, pluginBundle);
		} else if ([handler respondsToSelector:@selector(loadPluginAtPath:)]) {
			success = (NSUInteger)[handler performSelector:@selector(loadPluginAtPath:) withObject:path];
			if (!success)
				NSLog(@"%@: Handler %@ could not load plug-in at path %@", [self class], handler, path);
		} else if ([handler respondsToSelector:@selector(loadPluginAtURL:)]) {
			success = (NSUInteger)[handler performSelector:@selector(loadPluginAtURL:) withObject:[NSURL fileURLWithPath:path]];
			if (!success)
				NSLog(@"%@: Handler %@ could not load plug-in at URL for path %@", [self class], handler, path);
		} else
			NSLog(@"warning: while loading plug-in at %@, tried to use plug-in handler %@, but it appears incapable of handling a plug-in", path, handler); //XXX should do this diagnostic when adding the handler
	}

}

#pragma mark -
#pragma mark Installing plug-ins

- (void) pluginInstalledSelector:(NSModalResponse)returnCode contextInfo:(void *)contextInfo {
   NSString *filename = (__bridge NSString*)contextInfo;
	if (returnCode == NSAlertSecondButtonReturn) {
      GrowlMenu *menu = [GrowlApplicationController sharedController].statusMenu;

      if (menu){
         NSCharacterSet *set = [NSCharacterSet URLPathAllowedCharacterSet];
         NSString *urlString = [[NSString stringWithFormat:@"growl://preferences/displays/%@", filename] stringByAddingPercentEncodingWithAllowedCharacters:set];
         [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
      }
   }
}

- (void) pluginExistsSelector:(NSModalResponse)returnCode contextInfo:(void *) contextInfo {
	NSString *filename = (__bridge NSString *)contextInfo;

	if (returnCode == NSAlertSecondButtonReturn) {
		//'Yes' to 'Do you want to overwrite [the installed plug-in with the version you double-clicked]?'
		NSString *pluginFile = filename.lastPathComponent;
		NSString *destination = [[NSHomeDirectory()
			stringByAppendingPathComponent:@"Library/Application Support/Growl/Plugins"]
			stringByAppendingPathComponent:pluginFile];
		NSFileManager *fileManager = [NSFileManager defaultManager];

		// first remove old copy if present
		[fileManager removeItemAtPath:destination error:nil];

		// copy new version to destination
		if ([fileManager copyItemAtPath:filename toPath:destination error:nil]) {
			[self dispatchPluginAtPath:destination];
			[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
			NSBundle *bundle = [NSBundle bundleWithPath:destination];
			NSDictionary *dict = [pluginsByBundleIdentifier valueForKey:bundle.bundleIdentifier];
			if(dict)
				[[GrowlTicketDatabase sharedInstance] makeDefaultConfig:NO forPluginDict:dict];
			if([self hasNativeArchitecture:destination])
            {
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:NSLocalizedString( @"Plugin installed", @"" )];
                [alert addButtonWithTitle:NSLocalizedString( @"No",  @"" )];
                [alert addButtonWithTitle:NSLocalizedString( @"Yes", @"" )];
                alert.informativeText = [NSString stringWithFormat:NSLocalizedString( @"Plugin '%@' has been installed successfully. Do you want to configure it now?", @"" ), pluginFile.stringByDeletingPathExtension];
                [alert beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow completionHandler:^(NSModalResponse returnCode2) {
                    [self pluginInstalledSelector:returnCode2 contextInfo:(__bridge_retained void *) [[bundle.infoDictionary valueForKey:(NSString*)kCFBundleNameKey] copy]];
                }];
            }
		} else {
			[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:NSLocalizedString(@"Plugin not installed", @"")];
            [alert addButtonWithTitle:NSLocalizedString(@"Ok", nil)];
            alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"There was an error while installing the plugin '%@'.", @""), pluginFile.stringByDeletingPathExtension];
            alert.alertStyle = NSAlertStyleCritical;
		}
	}
}

- (void) installPluginFromPath:(NSString *)filename {
	NSString *pluginFile = filename.lastPathComponent;
	NSString *destination = [[NSHomeDirectory()
		stringByAppendingPathComponent:@"Library/Application Support/Growl/Plugins"]
		stringByAppendingPathComponent:pluginFile];
	// retain a copy of the filename because it is passed as context to the sheetDidEnd selectors
	NSString *filenameCopy = [filename copy];

	//Check to see if we've got valid architectures in this plugin for our use, if not, bail.
	if(![self hasNativeArchitecture:filenameCopy]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString( @"Plugin missing native architecture", @"" )];
        [alert addButtonWithTitle:NSLocalizedString( @"No",  @"" )];
        [alert addButtonWithTitle:NSLocalizedString( @"Yes", @"" )];
        alert.informativeText = [NSString stringWithFormat:NSLocalizedString( @"Plugin '%@' will not work on this Mac running this version of Mac OS X. Install it anyway?", @"" ), pluginFile.stringByDeletingPathExtension];
        [alert beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow completionHandler:^(NSModalResponse returnCode) {
            [self pluginExistsSelector:returnCode contextInfo:(__bridge void *)(filenameCopy)];
        }];
	}
	else {
		if ([[NSFileManager defaultManager] fileExistsAtPath:destination]) {
			// plugin already exists at destination
			[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:NSLocalizedString( @"Plugin already exists", @"" )];
            [alert addButtonWithTitle:NSLocalizedString( @"No",  @"" )];
            [alert addButtonWithTitle:NSLocalizedString( @"Yes", @"" )];
            alert.informativeText = [NSString stringWithFormat:NSLocalizedString( @"Plugin '%@' is already installed, do you want to overwrite it?", @"" ), pluginFile.stringByDeletingPathExtension];
            [alert beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow completionHandler:^(NSModalResponse returnCode) {
                [self pluginExistsSelector:returnCode contextInfo:(__bridge void *)(filenameCopy)];
            }];
		} else {
			[self pluginExistsSelector:NSAlertSecondButtonReturn contextInfo:(__bridge void *)(filenameCopy)];
		}
	}
}

- (BOOL)hasNativeArchitecture:(NSString*)filename {	
	BOOL result = NO;
	NSInteger currentArchitecture = 0;
#if defined(__ppc__) && __ppc__
	currentArchitecture = NSBundleExecutableArchitecturePPC;
#elif defined(__i386__) && __i386__
	currentArchitecture = NSBundleExecutableArchitectureI386;
#elif defined(__x86_64__) && __x86_64__
	currentArchitecture = NSBundleExecutableArchitectureX86_64;
#else
	#error unsupported architecture
#endif
	NSBundle *pluginBundle = [NSBundle bundleWithPath:filename];
	NSString *executablePath = pluginBundle.executablePath;
	//we check to see if there is actually an executable in this plugin, it could be a growlStyle, under which we accept it as valid.
	if(executablePath && [[NSFileManager defaultManager] fileExistsAtPath:executablePath]) {
		NSArray *pluginArchitectures = pluginBundle.executableArchitectures;
		if([pluginArchitectures containsObject:@(currentArchitecture)])
			result = YES;
	}
	else {
		result = YES;
	}

	return result;
}

#pragma mark FSEvents

- (void) handleFileSystemEventFromStream:(ConstFSEventStreamRef)eventStream
							  eventPaths:(NSArray *)paths
							  eventFlags:(const FSEventStreamEventFlags [])eventFlags
								eventIDs:(const FSEventStreamEventId [])eventIDs
{
	if (eventStream == pluginsDirectoryEventStream) {
		NSFileManager *mgr = [NSFileManager defaultManager];

		//XXX We should make this properly support case-insensitive comparison, for events where the user renamed a plug-in and changed only the case of some letters.
		NSMutableSet *currentlyExistingPluginPaths = [NSMutableSet set];

		for (NSString *dirPath in paths) {
			NSError *error = nil;
			NSArray *filenames = [mgr contentsOfDirectoryAtPath:dirPath error:&error];
			for (NSString *filename in filenames) {
				[currentlyExistingPluginPaths addObject:[dirPath stringByAppendingPathComponent:filename]];
			}
		}

		NSSet *previouslyKnownPluginPaths = [self.allPluginDictionaries valueForKey:GrowlPluginInfoKeyPath];

		NSMutableSet *deletedPluginPaths = [previouslyKnownPluginPaths mutableCopy];
		[deletedPluginPaths minusSet:currentlyExistingPluginPaths];

		NSMutableSet *newPluginPaths = [currentlyExistingPluginPaths mutableCopy];
		[newPluginPaths minusSet:previouslyKnownPluginPaths];

		//XXX Handle deleted plug-ins.

		NSWorkspace *wksp = [NSWorkspace sharedWorkspace];
		for (NSString *path in newPluginPaths) {
			NSString *pathExtension = path.pathExtension;
			NSString *fileType;
			[wksp getFileType:&fileType forFile:path];
			if (pluginHandlers[pathExtension] || (fileType && pluginHandlers[fileType])) {
				[self dispatchPluginAtPath:path];
			}
		}
	}
}

@end

static Boolean caseInsensitiveStringComparator(const void *value1, const void *value2) {
	Class NSStringClass = [NSString class];
	return [(__bridge id)value1 isKindOfClass:NSStringClass] \
	    && [(__bridge id)value2 isKindOfClass:NSStringClass]  \
	    && ([(__bridge NSString *)value1 caseInsensitiveCompare:(__bridge NSString *)value2] == NSOrderedSame);
}

static CFHashCode passthroughStringHash(const void *value) {
	return ((__bridge NSString *)value).lowercaseString.hash;
}

#pragma mark -

@implementation NSDictionary (GrowlPluginKeys)

- (NSString *) pluginName {
	return self[GrowlPluginInfoKeyName];
}
- (NSString *) pluginAuthor {
	return self[GrowlPluginInfoKeyAuthor];
}
- (NSString *) pluginDescription {
	return self[GrowlPluginInfoKeyDescription];
}
- (NSString *) pluginVersion {
	return self[GrowlPluginInfoKeyVersion];
}
- (NSBundle *) pluginBundle {
	return self[GrowlPluginInfoKeyBundle];
}
- (NSString *) pluginPath {
	return self[GrowlPluginInfoKeyPath];
}
- (NSSet *) pluginTypes {
	return self[GrowlPluginInfoKeyTypes];
}
- (NSString *) pluginHumanReadableName {
	return self[GrowlPluginInfoKeyHumanReadableName];
}
- (NSString *) pluginIdentifier {
	return self[GrowlPluginInfoKeyIdentifier];
}
- (GrowlPlugin *) pluginInstance {
	return self[GrowlPluginInfoKeyInstance];
}

@end

#define ASSERT_IN_FUNCTION(condition, desc, ...)                                                      \
	[[NSAssertionHandler currentHandler] handleFailureInFunction:[NSString stringWithFormat:@"%s", __func__] \
															file:[NSString stringWithFormat:@"%s", __FILE__]  \
													  lineNumber:__LINE__                                \
													 description:desc, __VA_ARGS__];

NSInteger comparePluginHandlerRegistrationOrder(id a, id b, void *context) {
	GrowlPluginController *self = (__bridge GrowlPluginController *)context;
	NSArray *allPluginHandlers = self.allPluginHandlers;

	NSUInteger aIndex = [allPluginHandlers indexOfObjectIdenticalTo:a];
	NSUInteger bIndex = [allPluginHandlers indexOfObjectIdenticalTo:b];

	ASSERT_IN_FUNCTION(aIndex != NSNotFound, @"Attempted to compare two plug-in handlers, but the first object was not a (registered) plug-in handler! Description of object: %@", a);
	ASSERT_IN_FUNCTION(bIndex != NSNotFound, @"Attempted to compare two plug-in handlers, but the second object was not a (registered) plug-in handler! Description of object: %@", b);

	if (aIndex < bIndex)
		return NSOrderedAscending;
	else if (aIndex > bIndex)
		return NSOrderedDescending;
	else
		return NSOrderedSame;
}

static void eventStreamCallback(ConstFSEventStreamRef eventStream, void *clientCallBackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIDs[]) {
	GrowlPluginController *self = (__bridge GrowlPluginController *)clientCallBackInfo;
	[self handleFileSystemEventFromStream:eventStream
							   eventPaths:(__bridge NSArray *)eventPaths
							   eventFlags:eventFlags
								 eventIDs:eventIDs];
}
