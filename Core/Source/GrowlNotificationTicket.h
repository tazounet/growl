//
//  GrowlNotificationTicket.h
//  Growl
//
//  Created by Karl Adam on 01.10.05.
//  Copyright 2005-2006 matrixPointer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GrowlApplicationTicket, GrowlDisplayPlugin;

@interface GrowlNotificationTicket : NSObject {
	NSString                *name;
	NSString				*humanReadableName;
	NSString				*notificationDescription;
	NSString                *sound;

	GrowlApplicationTicket  *__weak ticket;        // Our owner
	NSString				*displayPluginName;
	GrowlDisplayPlugin      *displayPlugin;
	int                      sticky;
	enum GrowlPriority       priority;
	unsigned                 GANReserved: 31;
	BOOL                    enabled: 1;
   BOOL                     logNotification: YES;
}

+ (GrowlNotificationTicket *) notificationWithName:(NSString *)name;
+ (GrowlNotificationTicket *) notificationWithDictionary:(NSDictionary *)dict;

- (instancetype)init NS_UNAVAILABLE;
- (GrowlNotificationTicket *) initWithName:(NSString *)name;
- (GrowlNotificationTicket *) initWithDictionary:(NSDictionary *)dict;
- (GrowlNotificationTicket *) initWithName:(NSString *)inName
						 humanReadableName:(NSString *)inHumanReadableName
				   notificationDescription:(NSString *)inNotificationDescription
								  priority:(enum GrowlPriority)inPriority
								   enabled:(BOOL)inEnabled
                        logEnabled:(BOOL)inLogEnabled
									sticky:(int)inSticky
						 displayPluginName:(NSString *)display
									 sound:(NSString *)sound NS_DESIGNATED_INITIALIZER;

#pragma mark -

- (NSDictionary *) dictionaryRepresentation;

- (BOOL) isEqualToNotification:(GrowlNotificationTicket *) other;
- (GrowlDisplayPlugin *) displayPlugin;

#pragma mark -
   

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *humanReadableName;
@property (nonatomic, strong) NSString *notificationDescription;
@property (nonatomic, assign) enum GrowlPriority priority;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL logNotification;
@property (nonatomic, assign) int sticky;
@property (nonatomic, weak) GrowlApplicationTicket *ticket;
@property (nonatomic, copy) NSString *displayPluginName;
@property (nonatomic, strong) NSString *sound;

@end
