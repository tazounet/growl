//
//  GrowlNotificationCenter.m
//  Growl
//
//  Created by Ingmar Stein on 27.04.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlNotificationCenter.h"

@implementation GrowlNotificationCenter
- (instancetype) init {
	if ((self = [super init])) {
		observers = [[NSMutableArray alloc] init];
	}
	return self;
}

- (oneway void) addObserver:(byref id<GrowlNotificationObserver>)observer {
	[observers addObject:observer];
}

- (oneway void) removeObserver:(byref id<GrowlNotificationObserver>)observer {
	[observers removeObject:observer];
}

- (void) notifyObservers:(NSDictionary *)notificationDict {
   [observers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		@try {
         [obj notifyWithDictionary:notificationDict];
      } @catch(NSException *ex) {
         NSLog(@"Exception while notifying observer: %@", ex);
      }
   }];
}

@end
