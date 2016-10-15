//
//  GrowlApplicationTicket.m
//  Growl
//
//  Created by Karl Adam on Tue Apr 27 2004.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details


#import <GrowlPlugins/GrowlDisplayPlugin.h>
#import "GrowlApplicationTicket.h"
#import "GrowlNotificationTicket.h"
#import "GrowlDefines.h"
#import "NSStringAdditions.h"
#import "NSWorkspaceAdditions.h"
#import "GrowlPathUtilities.h"
#import "GrowlImageAdditions.h"
#include "CFURLAdditions.h"

#define UseDefaultsKey			@"useDefaults"
#define TicketEnabledKey		@"ticketEnabled"
#define PositionTypeKey			@"positionType"
#define LoggingEnabled        @"Logging"

#pragma mark -

@implementation GrowlApplicationTicket
@synthesize appID;
@synthesize appPath;
@synthesize hostName;
@synthesize appNameHostName;
@synthesize isLocalHost;

@synthesize hasChanged = changed;
@synthesize useDefaults;
@synthesize selectedPosition = selectedCustomPosition;
@synthesize positionType;
@synthesize ticketEnabled;
@synthesize displayPluginName;

@synthesize loggingEnabled;

+ (BOOL) isValidAutoDiscoverableTicketDictionary:(NSDictionary *)dict {
	if (!dict)
		return NO;

	NSNumber *versionNum = dict[GROWL_TICKET_VERSION];
	if (versionNum.intValue == 1) {
		return dict[GROWL_NOTIFICATIONS_ALL]
			&& dict[GROWL_APP_NAME];
	} else {
		return NO;
	}
}

+ (BOOL) isKnownTicketVersion:(NSDictionary *)dict {
	id version = dict[GROWL_TICKET_VERSION];
	return version && ([version intValue] == 1);
}

#pragma mark -

+ (instancetype) ticketWithDictionary:(NSDictionary *)ticketDict {
	return [[GrowlApplicationTicket alloc] initWithDictionary:ticketDict];
}

- (instancetype) initWithDictionary:(NSDictionary *)ticketDict {
	if (!ticketDict) {
		NSParameterAssert(ticketDict != nil);
		return nil;
	}
	if ((self = [self init])) {
		synchronizeOnChanges = NO;

		appName = ticketDict[GROWL_APP_NAME];
		appId = ticketDict[GROWL_APP_ID];
      NSString *host = [ticketDict valueForKey:GROWL_NOTIFICATION_GNTP_SENT_BY];
      if ([host hasSuffix:@".local"]) {
         host = [host substringToIndex:(host.length - (@".local").length)];
      }
      if(!host){
         isLocalHost = YES;
      }else {
         if ([ticketDict valueForKey:@"isGrowlAppLocalHost"]) {
            isLocalHost = [[ticketDict valueForKey:@"isGrowlAppLocalHost"] boolValue];
         }else {
            isLocalHost = host.isLocalHost;
         }
      }
      if(isLocalHost){
         appNameHostName = appName;
      }else {
         hostName = host;
         appNameHostName = [[NSString alloc] initWithFormat:@"%@ - %@", hostName, appName];
      }
      
		if (appId && ![appId isKindOfClass:[NSString class]]) {
			NSLog(@"Ticket for application %@ contains invalid bundle ID %@! Rejecting.", appName, appId);
			return nil;
		}
      
      if ([ticketDict valueForKey:LoggingEnabled])
         loggingEnabled = [[ticketDict valueForKey:LoggingEnabled] boolValue];
      else
         loggingEnabled = YES;

		humanReadableNames = ticketDict[GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES];
		notificationDescriptions = ticketDict[GROWL_NOTIFICATIONS_DESCRIPTIONS];

		//Get all the notification names and the data about them
		allNotificationNames = ticketDict[GROWL_NOTIFICATIONS_ALL];
		NSAssert1(allNotificationNames, @"Ticket dictionaries must contain a list of all their notifications (application name: %@)", appName);

		NSArray *inDefaults = ticketDict[GROWL_NOTIFICATIONS_DEFAULT];
		if (!inDefaults) inDefaults = allNotificationNames;

		NSMutableDictionary *allNotificationsTemp = [[NSMutableDictionary alloc] initWithCapacity:allNotificationNames.count];
		NSMutableArray *allNamesTemp = [[NSMutableArray alloc] initWithCapacity:allNotificationNames.count];
		for (id obj in allNotificationNames) {
			NSString *name;
			GrowlNotificationTicket *notification;
			if ([obj isKindOfClass:[NSString class]]) {
				name = obj;
				notification = [[GrowlNotificationTicket alloc] initWithName:obj];
			} else {
				name = obj[@"Name"];
				notification = [[GrowlNotificationTicket alloc] initWithDictionary:obj];
			}
			[allNamesTemp addObject:name];
			notification.ticket = self;

			//Set the human readable name if we were supplied one
			notification.humanReadableName = humanReadableNames[name];
			notification.notificationDescription = notificationDescriptions[name];

			allNotificationsTemp[name] = notification;
		}
		allNotifications = allNotificationsTemp;
		allNotificationNames = allNamesTemp;

		BOOL doLookup = YES;
		NSString *fullPath = nil;
		id location = ticketDict[GROWL_APP_LOCATION];
		if (location) {
			if ([location isKindOfClass:[NSDictionary class]]) {
				NSDictionary *file_data = ((NSDictionary *)location)[@"file-data"];
				NSURL *url = fileURLWithDockDescription(file_data);
				if (url) {
					fullPath = url.path;
				}
			} else if ([location isKindOfClass:[NSString class]]) {
				fullPath = location;
				if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath])
					fullPath = nil;
			} else if ([location isKindOfClass:[NSNumber class]]) {
				doLookup = [location boolValue];
			}
		}
		if (!fullPath && doLookup) {
			if (appId) {
                NSArray *array = CFBridgingRelease(LSCopyApplicationURLsForBundleIdentifier((__bridge CFStringRef)appId, NULL));
                if (array != nil) {
                    NSURL *url = array[0];
                    
                    fullPath = url.path;
                }
			}
			if (!fullPath)
				fullPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:appName];
		}
		appPath = fullPath;
//		NSLog(@"got appPath: %@", appPath);

		self.iconData = ticketDict[GROWL_APP_ICON_DATA];

		id value = ticketDict[UseDefaultsKey];
		if (value)
			useDefaults = [value boolValue];
		else
			useDefaults = YES;

		value = ticketDict[TicketEnabledKey];
		if (value)
			ticketEnabled = [value boolValue];
		else
			ticketEnabled = YES;

		displayPluginName = [ticketDict[GrowlDisplayPluginKey] copy];
		
		value = ticketDict[PositionTypeKey];
		if (value)
			positionType = [value integerValue];
		else
			positionType = 0;	
		
		value = ticketDict[GROWL_POSITION_PREFERENCE_KEY];
		if (value)
			selectedCustomPosition = [value integerValue];
		else
			selectedCustomPosition = 0;				

		[self setDefaultNotifications:inDefaults];

		changed = YES;
		synchronizeOnChanges = YES;
		
		[self addObserver:self forKeyPath:@"displayPluginName" options:NSKeyValueObservingOptionNew context:(__bridge void *)(self)];
		[self addObserver:self forKeyPath:@"ticketEnabled" options:NSKeyValueObservingOptionNew context:(__bridge void *)(self)];
		[self addObserver:self forKeyPath:@"positionType" options:NSKeyValueObservingOptionNew context:(__bridge void *)(self)];
		[self addObserver:self forKeyPath:@"selectedPosition" options:NSKeyValueObservingOptionNew context:(__bridge void *)(self)];
		[self addObserver:self forKeyPath:@"loggingEnabled" options:NSKeyValueObservingOptionNew context:(__bridge void *)(self)];
	}
	return self;
}

- (void) dealloc {
	
	[self removeObserver:self forKeyPath:@"displayPluginName"];
	[self removeObserver:self forKeyPath:@"ticketEnabled"];
	[self removeObserver:self forKeyPath:@"positionType"];
	[self removeObserver:self forKeyPath:@"selectedPosition"];
	[self removeObserver:self forKeyPath:@"loggingEnabled"];   
	

}

#pragma mark -

- (instancetype) initTicketFromPath:(NSString *) ticketPath {	
	NSURL *ticketURL = [NSURL fileURLWithPath:ticketPath isDirectory:NO];
	NSDictionary *ticketDict = [NSDictionary dictionaryWithContentsOfURL:ticketURL];

	if (!ticketDict) {
		NSLog(@"Tried to init a ticket from this file, but it isn't a ticket file: %@", ticketPath);
		return nil;
	}

	self = [self initWithDictionary:ticketDict];
	return self;
}

- (instancetype) initTicketForApplication: (NSString *) inApp {
	return [self initTicketFromPath:[[[[GrowlPathUtilities growlSupportDirectory]
										stringByAppendingPathComponent:@"Tickets"]
										stringByAppendingPathComponent:inApp]
										stringByAppendingPathExtension:@"growlTicket"]];
}

- (NSString *) path {
	NSString *destDir = [GrowlPathUtilities growlSupportDirectory];
	destDir = [destDir stringByAppendingPathComponent:@"Tickets"];
	destDir = [destDir stringByAppendingPathComponent:[appNameHostName stringByAppendingPathExtension:@"growlTicket"]];
	return destDir;
}

- (void) saveTicket {
	NSString *destDir = [GrowlPathUtilities growlSupportDirectory];
	destDir = [destDir stringByAppendingPathComponent:@"Tickets"];

	[self saveTicketToPath:destDir];
}

- (void) saveTicketToPath:(NSString *)destDir {
	// Save a Plist file of this object to configure the prefs of apps that aren't running
	// construct a dictionary of our state data then save that dictionary to a file.
	NSString *savePath = [destDir stringByAppendingPathComponent:[appNameHostName stringByAppendingPathExtension:@"growlTicket"]];
	NSMutableArray *saveNotifications = [[NSMutableArray alloc] initWithCapacity:allNotifications.count];
	for (GrowlNotificationTicket *obj in [allNotifications objectEnumerator]) {
		[saveNotifications addObject:[obj dictionaryRepresentation]];
	}
	
	NSDictionary *file_data = nil;
	if (appPath) {
		NSURL *url = [[NSURL alloc] initFileURLWithPath:appPath];
		file_data = dockDescriptionWithURL(url);
	}

	id location = file_data ? @{@"file-data": file_data} : appPath;
	if (!location)
		location = @NO;

	NSNumber *useDefaultsValue = @(useDefaults);
	NSNumber *ticketEnabledValue = @(ticketEnabled);
	NSNumber *positionTypeValue = @(positionType);
	NSNumber *selectedCustomPositionValue = @(selectedCustomPosition);
   NSNumber *localHost = @(isLocalHost);
   NSNumber *logNumber = @(loggingEnabled);
	NSData *theIconData = iconData;
	NSMutableDictionary *saveDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
		appName,						GROWL_APP_NAME,
		saveNotifications,				GROWL_NOTIFICATIONS_ALL,
		defaultNotifications,			GROWL_NOTIFICATIONS_DEFAULT,
		theIconData,					GROWL_APP_ICON_DATA,
		useDefaultsValue,				UseDefaultsKey,
		ticketEnabledValue,				TicketEnabledKey,
		positionTypeValue,				PositionTypeKey,
		selectedCustomPositionValue,	GROWL_POSITION_PREFERENCE_KEY,
		location,						GROWL_APP_LOCATION,
      localHost,               @"isGrowlAppLocalHost",
      logNumber,               LoggingEnabled,
		nil];
	
   if (hostName)
      saveDict[GROWL_NOTIFICATION_GNTP_SENT_BY] = hostName;
      
	if (displayPluginName)
		saveDict[GrowlDisplayPluginKey] = displayPluginName;

	if (humanReadableNames)
		saveDict[GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES] = humanReadableNames;

	if (notificationDescriptions)
		saveDict[GROWL_NOTIFICATIONS_DESCRIPTIONS] = notificationDescriptions;

	if (appId)
		saveDict[GROWL_APP_ID] = appId;

	NSData *plistData;
    NSError *error;
    plistData = [NSPropertyListSerialization dataWithPropertyList:saveDict
                                                           format:NSPropertyListBinaryFormat_v1_0
                                                          options:0
                                                            error:&error];
	if (plistData)
		[plistData writeToFile:savePath atomically:YES];
	else
		NSLog(@"Error writing ticket for application %@: %@", appName, error);

	changed = NO;
}

//All this needs to do now is save the ticket to disk, everything references the one true ticket for the application
- (void) doSynchronize {
	[self saveTicket];
}

- (void) synchronize {
	if (synchronizeOnChanges) {
		//Coalesce a series of changes into a single message; this makes mass changes (such as registration) much faster.
		[NSObject cancelPreviousPerformRequestsWithTarget:self
												 selector:@selector(doSynchronize)
												   object:nil];
		[self performSelector:@selector(doSynchronize)
				   withObject:nil
				   afterDelay:0.5];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(([keyPath isEqualToString:@"displayPluginName"] ||
	    [keyPath isEqualToString:@"ticketEnabled"] ||
	    [keyPath isEqualToString:@"positionType"] ||
	    [keyPath isEqualToString:@"selectedPosition"] ||
       [keyPath isEqualToString:@"loggingEnabled"]) && [object isEqual:self])
	{
		[self synchronize];
	}	
}
#pragma mark -

- (NSData *) iconData {
	if (!iconData) {
		if (appPath) {
			icon = [[NSWorkspace sharedWorkspace] iconForFile:appPath];
			iconData = icon.PNGRepresentation;
		}
		if (!iconData) {
			icon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericApplicationIcon)];
			icon.size = NSMakeSize(128.0f, 128.0f);
			iconData = icon.PNGRepresentation;
		}
	}
	return iconData;
}

- (void) setIconData:(NSData *)inIconData {
	if (iconData != inIconData) {
		if (iconData && [inIconData isEqual:iconData])
			return;
		changed = YES;

		//Test that this data is valid. If it isn't, set the data to nil instead.
		BOOL isValidData = NO;
		for (Class imageRepClass in [NSImageRep registeredImageRepClasses]) {
			if ([imageRepClass canInitWithData:inIconData]) {
				isValidData = YES;
				break;
			}
		}
		if (!isValidData)
			inIconData = nil;

		iconData = inIconData;
		 icon = nil;
	}
}

- (void)setIcon:(NSImage *)inIcon {
	self.iconData = inIcon.PNGRepresentation;

	icon = inIcon;
}

- (NSString *) applicationName {
   return appName;
}

- (GrowlDisplayPlugin *) displayPlugin {
   return (GrowlDisplayPlugin *)[[GrowlPluginController sharedController] displayPluginInstanceWithName:displayPluginName author:nil version:nil type:nil];
}

#pragma mark -

- (NSString *) description {
	return [NSString stringWithFormat:@"<GrowlApplicationTicket: %p>{\n\tApplicationName: \"%@\"\n\ticon data length: %lu\n\tAll Notifications: %@\n\tDefault Notifications: %@\n\tAllowed Notifications: %@\n\tUse Defaults: %@\n}",
		self, appName, iconData.length, allNotifications, defaultNotifications, self.allowedNotifications, ( useDefaults ? @"YES" : @"NO" )];
}

#pragma mark -

- (void) reregisterWithAllNotifications:(NSArray *)inAllNotes defaults:(id)inDefaults iconData:(NSData *)inIconData {
	if (!useDefaults) {
		/*We want to respect the user's preferences, but if the application has
		 *	added new notifications since it last registered, we want to enable those
		 *	if the application says to.
		 */
		NSMutableDictionary *allNotesCopy = [allNotifications mutableCopy];

		if ([inDefaults respondsToSelector:@selector(objectEnumerator)] ) {
			Class NSNumberClass = [NSNumber class];
			NSUInteger numAllNotifications = inAllNotes.count;
			for (id obj in inDefaults) {
				NSString *note;
				if ([obj isKindOfClass:NSNumberClass]) {
					//it's an index into the all-notifications list
					unsigned notificationIndex = [obj unsignedIntValue];
					if (notificationIndex >= numAllNotifications) {
						NSLog(@"WARNING: application %@ tried to allow notification at index %u by default, but there is no such notification in its list of %u", appName, (unsigned int)notificationIndex, (unsigned int)numAllNotifications);
						note = nil;
					} else {
						note = inAllNotes[notificationIndex];
					}
				} else {
					//it's probably a notification name
					note = obj;
				}

				if (note && !allNotesCopy[note]) {
					GrowlNotificationTicket *ticket = [GrowlNotificationTicket notificationWithName:note];
					ticket.humanReadableName = humanReadableNames[note];
					ticket.notificationDescription = notificationDescriptions[note];
					allNotesCopy[note] = ticket;
				}
			}

		} else if ([inDefaults isKindOfClass:[NSIndexSet class]]) {
			NSUInteger notificationIndex;
			NSUInteger numAllNotifications = inAllNotes.count;
			NSIndexSet *iset = (NSIndexSet *)inDefaults;
			for (notificationIndex = iset.firstIndex; notificationIndex != NSNotFound; notificationIndex = [iset indexGreaterThanIndex:notificationIndex]) {
				if (notificationIndex >= numAllNotifications) {
					NSLog(@"WARNING: application %@ tried to allow notification at index %u by default, but there is no such notification in its list of %u", appName, (unsigned int)notificationIndex, (unsigned int)numAllNotifications);
					// index sets are sorted, so we can stop here
					break;
				} else {
					NSString *note = inAllNotes[notificationIndex];
					if (!allNotesCopy[note]) {
						GrowlNotificationTicket *ticket = [GrowlNotificationTicket notificationWithName:note];
						ticket.humanReadableName = humanReadableNames[note];
						ticket.notificationDescription = notificationDescriptions[note];
						allNotesCopy[note] = ticket;
					}
				}
			}

		} else {
			if (inDefaults)
				NSLog(@"WARNING: application %@ passed an invalid object for the default notifications: %@.", appName, inDefaults);
		}

		if (![allNotifications isEqual:allNotesCopy]) {
			allNotifications = allNotesCopy;
			changed = YES;
		} else {
		}
	}

	//ALWAYS set all notifications list first, to enable handling of numeric indices in the default notifications list!
	self.allNotifications = inAllNotes;
	[self setDefaultNotifications:inDefaults];

	self.iconData = inIconData;
}

- (void) reregisterWithDictionary:(NSDictionary *)dict {
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];

	NSData *appIconData = dict[GROWL_APP_ICON_DATA];
	NSString *bundleId = dict[GROWL_APP_ID];

	if (bundleId != appId && ![bundleId isEqualToString:appId]) {
		appId = bundleId;
		changed = YES;
	}

	//XXX - should assimilate reregisterWithAllNotifications:defaults:iconData: here
	NSArray	*all      = dict[GROWL_NOTIFICATIONS_ALL];
	NSArray	*defaults = dict[GROWL_NOTIFICATIONS_DEFAULT];

	NSDictionary *newNames = dict[GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES];
	if (newNames != humanReadableNames && ![newNames isEqual:humanReadableNames]) {
		humanReadableNames = newNames;
		changed = YES;
	}

	NSDictionary *newDescriptions = dict[GROWL_NOTIFICATIONS_DESCRIPTIONS];
	if (newDescriptions != notificationDescriptions && ![newDescriptions isEqual:notificationDescriptions]) {
		notificationDescriptions = newDescriptions;
		changed = YES;
	}

	if (!defaults) defaults = all;
	[self reregisterWithAllNotifications:all
								defaults:defaults
								iconData:appIconData];

	NSString *fullPath = nil;
	id location = dict[GROWL_APP_LOCATION];
	if (location) {
		if ([location isKindOfClass:[NSDictionary class]]) {
			NSDictionary *file_data = location[@"file-data"];
			NSURL *url = fileURLWithDockDescription(file_data);
			if (url) {
				fullPath = url.path;
			}
		} else if ([location isKindOfClass:[NSString class]]) {
			fullPath = location;
			if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath])
				fullPath = nil;
		}
		/* Don't handle the NSNumber case here, the app might have moved and we
		 * use the re-registration to update our stored appPath.
		*/
	}
	if (!fullPath) {
		if (appId) {
            NSArray *array = CFBridgingRelease(LSCopyApplicationURLsForBundleIdentifier((__bridge CFStringRef)appId, NULL));
            if (array != nil) {
                NSURL *url = array[0];
                
				fullPath = url.path;
			}
		}
		if (!fullPath)
			fullPath = [workspace fullPathForApplication:appName];
	}
	if (fullPath != appPath && ![fullPath isEqualToString:appPath]) {
		appPath = fullPath;
		changed = YES;
	}
}

- (NSArray *) allNotifications {
	return allNotifications.allKeys;
}

- (void) setAllNotifications:(NSArray *)inArray {
	if (allNotificationNames != inArray) {
		if ([inArray isEqualToArray:allNotificationNames])
			return;
		changed = YES;
		allNotificationNames = inArray;

		//We want to keep all of the old notification settings and create entries for the new ones
		NSMutableDictionary *tmp = [[NSMutableDictionary alloc] initWithCapacity:inArray.count];
		id obj;
		for (id key in inArray) {
			obj = allNotifications[key];
			if (obj) {
				tmp[key] = obj;
			} else {
				GrowlNotificationTicket *notification = [[GrowlNotificationTicket alloc] initWithName:key];
				notification.humanReadableName = humanReadableNames[key];
				notification.notificationDescription = notificationDescriptions[key];
				tmp[key] = notification;
			}
		}
		allNotifications = tmp;

		// And then make sure the list of default notifications also doesn't have any straglers...
		NSMutableSet *cur = [[NSMutableSet alloc] initWithArray:defaultNotifications];
		NSSet *new = [[NSSet alloc] initWithArray:allNotificationNames];
		[cur intersectSet:new];
		defaultNotifications = cur.allObjects;
	}
}

- (NSArray *) defaultNotifications {
	return defaultNotifications;
}

- (void) setDefaultNotifications:(id)inObject {
	if (!allNotifications) {
		/*WARNING: if you try to pass an array containing numeric indices, and
		 *	the all-notifications list has not been supplied yet, the indices
		 *	WILL NOT be dereferenced. ALWAYS set the all-notifications list FIRST.
		 */
		if (![defaultNotifications isEqual:inObject]) {
			defaultNotifications = inObject;
			changed = YES;
		}
	} else if ([inObject isKindOfClass:NSClassFromString(@"NSArray")] ) {
		NSUInteger numDefaultNotifications;
		NSUInteger numAllNotifications = allNotificationNames.count;
		if ([inObject respondsToSelector:@selector(count)])
			numDefaultNotifications = [inObject count];
		else
			numDefaultNotifications = numAllNotifications;
		NSMutableArray *mDefaultNotifications = [[NSMutableArray alloc] initWithCapacity:numDefaultNotifications];
		Class NSNumberClass = [NSNumber class];
		for (NSNumber *num in inObject) {
			if ([num isKindOfClass:NSNumberClass]) {
				//it's an index into the all-notifications list
				unsigned notificationIndex = num.unsignedIntValue;
				if (notificationIndex >= numAllNotifications)
					NSLog(@"WARNING: application %@ tried to allow notification at index %u by default, but there is no such notification in its list of %u", appName, (unsigned int)notificationIndex, (unsigned int)numAllNotifications);
				else
					[mDefaultNotifications addObject:allNotificationNames[notificationIndex]];
			} else {
				//it's probably a notification name
				[mDefaultNotifications addObject:num];
			}
		}
		if (![defaultNotifications isEqualToArray:mDefaultNotifications]) {
			defaultNotifications = mDefaultNotifications;
			changed = YES;
		} else {
		}
	} else if ([inObject isKindOfClass:[NSIndexSet class]]) {
		NSUInteger notificationIndex;
		NSUInteger numAllNotifications = allNotificationNames.count;
		NSIndexSet *iset = (NSIndexSet *)inObject;
		NSMutableArray *mDefaultNotifications = [[NSMutableArray alloc] initWithCapacity:iset.count];
		for (notificationIndex = iset.firstIndex; notificationIndex != NSNotFound; notificationIndex = [iset indexGreaterThanIndex:notificationIndex]) {
			if (notificationIndex >= numAllNotifications) {
				NSLog(@"WARNING: application %@ tried to allow notification at index %u by default, but there is no such notification in its list of %u", appName, (unsigned int)notificationIndex, (unsigned int)numAllNotifications);
				// index sets are sorted, so we can stop here
				break;
			} else {
				[mDefaultNotifications addObject:allNotificationNames[notificationIndex]];
			}
		}
		if (![defaultNotifications isEqualToArray:mDefaultNotifications]) {
			defaultNotifications = mDefaultNotifications;
			changed = YES;
		} else {
		}
	} else {
		if (inObject)
			NSLog(@"WARNING: application %@ passed an invalid object for the default notifications: %@.", appName, inObject);
		if (![defaultNotifications isEqualToArray:allNotificationNames]) {
			defaultNotifications = allNotificationNames;
			changed = YES;
		}
	}

	if (useDefaults)
		[self setAllowedNotificationsToDefault];
}

- (NSArray *) allowedNotifications {
	NSMutableArray* allowed = [NSMutableArray array];

	for (GrowlNotificationTicket *obj in [allNotifications objectEnumerator])
		if (obj.enabled)
			[allowed addObject:obj.name];
	return allowed;
}

- (void) setAllowedNotifications:(NSArray *) inArray {
	NSSet *allowed = [[NSSet alloc] initWithArray:inArray];

	for (GrowlNotificationTicket *obj in [allNotifications objectEnumerator]) {
		obj.enabled = [allowed containsObject:obj.name];
	}

	useDefaults = NO;
}

- (void) setAllowedNotificationsToDefault {
	self.allowedNotifications = defaultNotifications;
	useDefaults = YES;
}

- (BOOL) isNotificationAllowed:(NSString *) name {
	return ticketEnabled && [allNotifications[name] enabled];
}

- (NSComparisonResult) caseInsensitiveCompare:(GrowlApplicationTicket *)aTicket {
   if(!hostName && !aTicket.hostName){
      return [self.applicationName caseInsensitiveCompare:aTicket.applicationName];
   }else if(hostName && !aTicket.hostName){
      return NSOrderedDescending;
   }else if(!hostName && aTicket.hostName){
      return NSOrderedAscending;
   }else if(hostName && aTicket.hostName){
      if([hostName caseInsensitiveCompare:aTicket.hostName] == NSOrderedSame)
         return [self.applicationName caseInsensitiveCompare:aTicket.applicationName];
      else
         return [hostName caseInsensitiveCompare:aTicket.hostName];
   }
	return [appNameHostName caseInsensitiveCompare:aTicket.appNameHostName];
}

- (NSDictionary*)registrationFormatDictionary
{
   
   NSMutableDictionary *regDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:appName, GROWL_APP_NAME,
                                                                                    allNotificationNames, GROWL_NOTIFICATIONS_ALL,
                                                                                    defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
                                                                                    iconData, GROWL_APP_ICON_DATA, nil];
   
   if (hostName && !hostName.isLocalHost)
      regDict[GROWL_NOTIFICATION_GNTP_SENT_BY] = hostName;
   
   if (humanReadableNames)
		regDict[GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES] = humanReadableNames;
   
	if (notificationDescriptions)
		regDict[GROWL_NOTIFICATIONS_DESCRIPTIONS] = notificationDescriptions;
   
	if (appId)
		regDict[GROWL_APP_ID] = appId;
   
   return regDict;
}

#pragma mark Notification Accessors
- (NSArray *) notifications {
	return allNotifications.allValues;
}

- (GrowlNotificationTicket *) notificationTicketForName:(NSString *)name {
	return allNotifications[name];
}
@end
