//
//  HWGrowlPluginController.m
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/2/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "HWGrowlPluginController.h"

//DO NOT TOUCH, FOR KEEPING LOCALIZATION SCRIPT SIMPLER
#define GrowlOffSwitchFake NSLocalizedString(@"OFF", @"If the string is too long, use O");
#define GrowlOnSwitchFake NSLocalizedString(@"ON", @"If the string is too long, use I");

@interface HWGrowlPluginController ()

@property (nonatomic, strong) NSMutableArray *notifiers;
@property (nonatomic, strong) NSMutableArray *monitors;

@end

@implementation HWGrowlPluginController

@synthesize plugins;
@synthesize notifiers;
@synthesize monitors;


-(instancetype)init {
	if((self = [super init])){
		self.plugins = [NSMutableArray array];
		self.notifiers = [NSMutableArray array];
		self.monitors = [NSMutableArray array];
		[self loadPlugins];
		
		[GrowlApplicationBridge setGrowlDelegate:self];
		[GrowlApplicationBridge setShouldUseBuiltInNotifications:YES];
		
		[self postRegistrationInit];
		
		if(self.onLaunchEnabled)
			[self fireOnLaunchNotes];
	}
	return self;
}

-(void)loadPlugins {
	NSString *pluginsPath = [NSBundle mainBundle].builtInPlugInsPath;
	NSArray *pluginBundles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:pluginsPath 
																										  error:nil];
	if(pluginBundles) {
		NSDictionary *disabledPlugins = [[NSUserDefaults standardUserDefaults] objectForKey:@"DisabledPlugins"];
		
		__weak HWGrowlPluginController *weakSelf = self;
		[pluginBundles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			NSString *bundlePath = [pluginsPath stringByAppendingPathComponent:obj];
			NSBundle *pluginBundle = [NSBundle bundleWithPath:bundlePath];
			if(pluginBundle && [pluginBundle load])
			{
				NSString *bundleID = pluginBundle.bundleIdentifier;
				id plugin = [[pluginBundle.principalClass alloc] init];
				if(plugin)
				{ 
					if([plugin conformsToProtocol:@protocol(HWGrowlPluginProtocol)])
					{
						[plugin setDelegate:self];
						BOOL disabled = NO;
						if(disabledPlugins && disabledPlugins[bundleID])
							disabled = [disabledPlugins[bundleID] boolValue];
						else if([plugin respondsToSelector:@selector(enabledByDefault)])
							disabled = ![plugin enabledByDefault];
						
						NSMutableDictionary *pluginDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:plugin, @"plugin", 
																	  @(disabled), @"disabled", nil];
						[weakSelf.plugins addObject:pluginDict];
						
						if([plugin conformsToProtocol:@protocol(HWGrowlPluginNotifierProtocol)])
							[weakSelf.notifiers addObject:plugin];
						if([plugin conformsToProtocol:@protocol(HWGrowlPluginMonitorProtocol)])
							[weakSelf.monitors addObject:plugin];
					}else{
						NSLog(@"%@ does not conform to HWGrowlPluginProtocol", NSStringFromClass(pluginBundle.principalClass));
					}
				}else{
					NSLog(@"We couldn't instantiate %@ for plugin %@", NSStringFromClass(pluginBundle.principalClass), bundleID);
				}
			}else{
				NSLog(@"%@ is not a bundle or could not be loaded", bundlePath);
			}
		}];
	}
	[plugins sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		return [[obj1[@"plugin"] pluginDisplayName] compare:[obj2[@"plugin"] pluginDisplayName]];
	}];
}
			
-(void)postRegistrationInit {
	[plugins enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if([obj[@"plugin"] respondsToSelector:@selector(postRegistrationInit)])
			[obj[@"plugin"] postRegistrationInit];
	}];
}

-(void)fireOnLaunchNotes {
	[notifiers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if([obj respondsToSelector:@selector(fireOnLaunchNotes)])
			[obj fireOnLaunchNotes];
	}];
}

-(void)notifyWithName:(NSString*)name 
                title:(NSString*)title
          description:(NSString*)description
                 icon:(NSData*)iconData
     identifierString:(NSString*)identifier
        contextString:(NSString*)context
               plugin:(id)plugin
{
	__block BOOL disabled = NO;
	[plugins enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if(obj[@"plugin"] == plugin) 
		{
			disabled = [obj[@"disabled"] boolValue];
			*stop = YES;
		}
	}];
	if(disabled)
		return;

    NSMutableDictionary *notification = [[NSMutableDictionary alloc] init];
    notification[GROWL_NOTIFICATION_NAME] = name;
    notification[GROWL_NOTIFICATION_TITLE] = title;
    notification[GROWL_NOTIFICATION_DESCRIPTION] = description;
    notification[GROWL_NOTIFICATION_IDENTIFIER] = identifier;
    if (iconData) notification[GROWL_NOTIFICATION_ICON_DATA] = iconData;

	NSString *contextCombined = nil;
	if(context && [context rangeOfString:@" : "].location != NSNotFound) {
		NSLog(@"found \" : \" in context string %@", context);
	}
	if(context && plugin && [context rangeOfString:@" : "].location == NSNotFound) {
		contextCombined = [NSString stringWithFormat:@"%@ : %@", NSStringFromClass([plugin class]), context];
        notification[GROWL_NOTIFICATION_CLICK_CONTEXT] = contextCombined;
        //notification[GROWL_NOTIFICATION_BUTTONTITLE_ACTION] = @"Action";
	}
	
/*    [GrowlApplicationBridge	notifyWithTitle:title
                                description:description
                           notificationName:name
                                   iconData:iconData
                                   priority:0
                                   isSticky:NO
                               clickContext:contextCombined
                                 identifier:identifier];*/

    [GrowlApplicationBridge notifyWithDictionary:notification];
}

-(BOOL)onLaunchEnabled {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowExisting"];
}

-(BOOL)pluginDisabled:(id)plugin {
	__block BOOL disabled = NO;
	[plugins enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if(obj[@"plugin"] == plugin) 
		{
			disabled = [obj[@"disabled"] boolValue];
			*stop = YES;
		}
	}];
	return disabled;
}

-(void)growlNotificationClosed:(id)clickContext viaClick:(BOOL)click {
	NSArray *components = [clickContext componentsSeparatedByString:@" : "];
	if(components.count < 2)
		return;
	NSString *classString = components[0];
	NSString *context = components[1];
	
	[notifiers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if([obj isKindOfClass:NSClassFromString(classString)]){
			if([obj respondsToSelector:@selector(noteClosed:byClick:)])
				[obj noteClosed:context byClick:click];
			*stop = YES;
		}
	}];
}

#pragma mark GrowlApplicationBridgeDelegate methods

- (NSDictionary*)registrationDictionaryForGrowl {
	NSMutableArray *allNotes = [NSMutableArray array];
	NSMutableArray *defaultNotes = [NSMutableArray array];
	NSMutableDictionary *descriptions = [NSMutableDictionary dictionary];
	NSMutableDictionary *localizedNames = [NSMutableDictionary dictionary];
	
	[notifiers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		id<HWGrowlPluginNotifierProtocol> notifier = obj;
		[allNotes addObjectsFromArray:notifier.noteNames];
		if([notifier defaultNotifications])
			[defaultNotes addObjectsFromArray:[notifier defaultNotifications]];
		[descriptions addEntriesFromDictionary:notifier.noteDescriptions];
		[localizedNames addEntriesFromDictionary:notifier.localizedNames];
	}];
	
	NSDictionary *regDict = @{GROWL_NOTIFICATIONS_ALL: allNotes,
									 GROWL_NOTIFICATIONS_DEFAULT: defaultNotes,
									 GROWL_NOTIFICATIONS_DESCRIPTIONS: descriptions,
									 GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES: localizedNames};
	return regDict;
}

- (NSString *) applicationNameForGrowl {
	return @"HardwareGrowler";
}

-(void)growlNotificationTimedOut:(id)clickContext {
	[self growlNotificationClosed:clickContext viaClick:NO];
}

-(void)growlNotificationWasClicked:(id)clickContext {
	[self growlNotificationClosed:clickContext viaClick:YES];
}

@end
