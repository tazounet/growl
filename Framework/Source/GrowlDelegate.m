//
//  GrowlDelegate.m
//  Growl
//
//  Created by Ingmar Stein on 16.04.05.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import "GrowlDelegate.h"

@implementation GrowlDelegate
@synthesize applicationNameForGrowl;
@synthesize applicationIconDataForGrowl;
@synthesize registrationDictionaryForGrowl = registrationDictionary;

- (instancetype) initWithAllNotifications:(NSArray *)allNotifications defaultNotifications:(NSArray *)defaultNotifications {
	if ((self = [self init])) {
		self.registrationDictionaryForGrowl = @{GROWL_NOTIFICATIONS_ALL: allNotifications,
                                                GROWL_NOTIFICATIONS_DEFAULT: defaultNotifications};
	}
	return self;
}


@end
