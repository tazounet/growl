//
//  GrowlRegisterScriptCommand.m
//  Growl
//
//  Created by Ingmar Stein on Tue Nov 09 2004.
//  Copyright (c) 2004-2011 The Growl Project. All rights reserved.
//

#import "GrowlRegisterScriptCommand.h"
#import "GrowlApplicationController.h"
#import "GrowlDefines.h"
#import "NSWorkspaceAdditions.h"
#import "GrowlImageAdditions.h"

#define KEY_APP_NAME					@"asApplication"
#define KEY_NOTIFICATIONS_ALL			@"allNotifications"
#define KEY_NOTIFICATIONS_DEFAULT		@"defaultNotifications"
#define KEY_ICON_APP_NAME				@"iconOfApplication"

#define ERROR_EXCEPTION					1

static const NSSize iconSize = { 1024.0f, 1024.0f };

@implementation GrowlRegisterScriptCommand

- (id) performDefaultImplementation {
	NSDictionary *args = self.evaluatedArguments;

	//XXX - should validate params better!
	NSString *appName				= args[KEY_APP_NAME];
	NSArray *allNotifications		= args[KEY_NOTIFICATIONS_ALL];
	NSArray *defaultNotifications	= args[KEY_NOTIFICATIONS_DEFAULT];
	NSString *iconOfApplication		= args[KEY_ICON_APP_NAME];

	//translate AppleScript (1-based) indices to C (0-based) indices.
	NSMutableArray *temp = [[NSMutableArray alloc] initWithArray:defaultNotifications];
	NSEnumerator *defaultEnum = [defaultNotifications objectEnumerator];
	NSNumber *num;
	Class NSNumberClass = [NSNumber class];
	for (unsigned i = 0U; (num = [defaultEnum nextObject]); ++i) {
		if ([num isKindOfClass:NSNumberClass]) {
			//it's an index.
			long value = num.longValue;
			if (value < 0) {
				/*negative indices are from the end.
				 *-1 is the last; -2 is second-to-last; etc.
				 */
				value = allNotifications.count + value;
			} else if (value > 0) {
				--value;
			} else {
				self.scriptErrorNumber = errAEIllegalIndex;
				self.scriptErrorString = @"Can't get item 0 of notifications.";
				return nil;
			}
			num = @(value);
			temp[i] = num;
		}
		++i;
	}
	defaultNotifications = temp;

	NSMutableDictionary *registerDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
		appName,              GROWL_APP_NAME,
		allNotifications,     GROWL_NOTIFICATIONS_ALL,
		defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
		nil];

	@try {
		if (iconOfApplication) {
			NSImage *icon = [[NSWorkspace sharedWorkspace] iconForApplication:iconOfApplication];
			if (icon) {
				icon.size = iconSize;
				registerDict[GROWL_APP_ICON_DATA] = icon.PNGRepresentation;
			}
		}

		[[GrowlApplicationController sharedController] registerApplicationWithDictionary:registerDict];
	} @catch(NSException *e) {
		NSLog(@"error processing AppleScript request: %@", e);
		[self setError:ERROR_EXCEPTION failure:e];
	}


	return nil;
}

- (void) setError:(int)errorCode {
	[self setError:errorCode failure:nil];
}

- (void) setError:(int)errorCode failure:(id)failure {
	self.scriptErrorNumber = errorCode;
	NSString *str;

	switch (errorCode) {
		case ERROR_EXCEPTION:
			str = [NSString stringWithFormat:@"Exception raised while processing: %@", failure];
			break;
		default:
			str = nil;
	}

	if (str)
		self.scriptErrorString = str;
}

@end
