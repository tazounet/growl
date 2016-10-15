//
//  GrowlTicketDatabaseNotification.m
//  Growl
//
//  Created by Daniel Siemer on 2/22/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlTicketDatabaseNotification.h"
#import "GrowlNotificationTicket.h"

@implementation GrowlTicketDatabaseNotification

@dynamic defaultEnabled;
@dynamic humanReadableName;
@dynamic priority;
@dynamic sticky;

-(void)setWithNotificationTicket:(GrowlNotificationTicket*)ticket {
   self.enabled = @(ticket.enabled);
   self.loggingEnabled = @(ticket.logNotification);
   self.name = ticket.name;
   self.humanReadableName = ticket.humanReadableName;
   self.priority = @(ticket.priority);
   self.sticky = @(ticket.sticky);
	
	[super importDisplayOrActionForName:ticket.displayPluginName];
}

- (NSComparisonResult) humanReadableNameCompare:(GrowlTicketDatabaseNotification*)inTicket {
	return [self.humanReadableName caseInsensitiveCompare:inTicket.humanReadableName];
}

@end
