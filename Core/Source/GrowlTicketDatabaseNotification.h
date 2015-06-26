//
//  GrowlTicketDatabaseNotification.h
//  Growl
//
//  Created by Daniel Siemer on 2/22/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "GrowlTicketDatabaseTicket.h"

@class GrowlNotificationTicket;

@interface GrowlTicketDatabaseNotification : GrowlTicketDatabaseTicket

@property (nonatomic, strong) NSNumber * defaultEnabled;
@property (nonatomic, strong) NSString * humanReadableName;
@property (nonatomic, strong) NSNumber * priority;
@property (nonatomic, strong) NSNumber * sticky;

-(void)setWithNotificationTicket:(GrowlNotificationTicket*)ticket;

@end
