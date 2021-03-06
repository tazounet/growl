//
//  GrowlDelegate.h
//  Growl
//
//  Created by Ingmar Stein on 16.04.05.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/GrowlApplicationBridge.h>

/*
 * A convenience class for applications which don't need feedback from
 * Growl (e.g. growlIsReady or growlNotificationWasClicked). It can also be used
 * with scripting languages such as F-Script (http://www.fscript.org).
 */
@interface GrowlDelegate : NSObject <GrowlApplicationBridgeDelegate> {
	NSDictionary	*registrationDictionary;
	NSString		*applicationNameForGrowl;
	NSData			*applicationIconDataForGrowl;
}
- (instancetype) initWithAllNotifications:(NSArray *)allNotifications defaultNotifications:(NSArray *)defaultNotifications;

@property (strong) NSString *applicationNameForGrowl;
@property (strong) NSData *applicationIconDataForGrowl;
@property (strong) NSDictionary *registrationDictionaryForGrowl;
@end
