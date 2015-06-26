//
//  GrowlTicketDatabaseTicket.h
//  Growl
//
//  Created by Daniel Siemer on 2/22/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "GrowlPositioningDefines.h"

@class GrowlTicketDatabaseTicket, GrowlTicketDatabaseDisplay, GrowlTicketDatabasePlugin;

@interface GrowlTicketDatabaseTicket : NSManagedObject

@property (nonatomic, strong) NSNumber * enabled;
@property (nonatomic, strong) NSData * iconData;
@property (nonatomic, strong) NSNumber * loggingEnabled;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSNumber * positionType;
@property (nonatomic, strong) NSNumber * selectedPosition;
@property (nonatomic, strong) NSString * ticketDescription;
@property (nonatomic, strong) NSNumber * useDisplay;
@property (nonatomic, strong) NSNumber * useParentActions;
@property (nonatomic, strong) NSSet *actions;
@property (nonatomic, strong) NSSet *children;
@property (nonatomic, strong) GrowlTicketDatabaseTicket *parent;
@property (nonatomic, strong) GrowlTicketDatabaseDisplay *display;
@end

@interface GrowlTicketDatabaseTicket (CoreDataGeneratedAccessors)

- (void)addActionsObject:(NSManagedObject *)value;
- (void)removeActionsObject:(NSManagedObject *)value;
- (void)addActions:(NSOrderedSet *)values;
- (void)removeActions:(NSOrderedSet *)values;
- (void)addChildrenObject:(GrowlTicketDatabaseTicket *)value;
- (void)removeChildrenObject:(GrowlTicketDatabaseTicket *)value;
- (void)addChildren:(NSSet *)values;
- (void)removeChildren:(NSSet *)values;

-(BOOL)isTicketAllowed;
-(GrowlTicketDatabaseDisplay*)resolvedDisplayConfig;
-(NSSet*)resolvedActionConfigSet;
-(GrowlPositionOrigin)resolvedDisplayOrigin;

-(void)setNewDisplayName:(NSString*)name;
-(void)importDisplayOrActionForName:(NSString*)name;

@end
