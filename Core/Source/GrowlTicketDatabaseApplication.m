//
//  GrowlTicketDatabaseApplication.m
//  Growl
//
//  Created by Daniel Siemer on 2/22/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlTicketDatabaseApplication.h"
#import "GrowlApplicationTicket.h"
#import "GrowlTicketDatabaseNotification.h"
#import "GrowlDefines.h"
#import "NSStringAdditions.h"
#include "CFURLAdditions.h"

@implementation GrowlTicketDatabaseApplication

@dynamic appID;
@dynamic appPath;

-(void)setWithApplicationTicket:(GrowlApplicationTicket*)ticket {
   self.enabled = [NSNumber numberWithBool:[ticket ticketEnabled]];
   self.iconData = [ticket iconData];
   self.loggingEnabled = [NSNumber numberWithBool:[ticket loggingEnabled]];
   self.name = ticket.applicationName;
   self.positionType = [NSNumber numberWithInteger:[ticket positionType]];
   self.selectedPosition = [NSNumber numberWithInteger:[ticket selectedPosition]];
   self.appID = ticket.appID;
   self.appPath = ticket.appPath;
	
	[super importDisplayOrActionForName:[ticket displayPluginName]];
   
   [[ticket notifications] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      GrowlTicketDatabaseNotification *note = [NSEntityDescription insertNewObjectForEntityForName:@"GrowlNotificationTicket"
                                                                            inManagedObjectContext:[self managedObjectContext]];
      [note setParent:self];
      [note setWithNotificationTicket:obj];
      [note setDefaultEnabled:[NSNumber numberWithBool:[[ticket defaultNotifications] containsObject:obj]]];
   }];
}

+(NSString*)fullPathForRegDictApp:(NSDictionary*)regDict {
	BOOL doLookup = YES;
	NSString *name = [regDict valueForKey:GROWL_APP_NAME];
	NSString *fullPath = nil;
	id location = [regDict objectForKey:GROWL_APP_LOCATION];
	if (location) {
		if ([location isKindOfClass:[NSDictionary class]]) {
			NSDictionary *file_data = [(NSDictionary *)location objectForKey:@"file-data"];
			NSURL *url = fileURLWithDockDescription(file_data);
			if (url) {
				fullPath = [url path];
			}
		} else if ([location isKindOfClass:[NSString class]]) {
			fullPath = location;
			if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath])
				fullPath = nil;
		} else if ([location isKindOfClass:[NSNumber class]]) {
			doLookup = [location boolValue];
		}
	}
   
   if (!fullPath && doLookup)
      fullPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:name];
	
	return fullPath;
}

+(BOOL)isNoteDefault:(NSString*)name inNoteArray:(NSArray*)allNotes forInDefaults:(id)inDefaults
{
	BOOL result = YES;
	if([allNotes containsObject:name]) {
		NSUInteger index = [allNotes indexOfObject:name];
		if([inDefaults isKindOfClass:[NSArray class]]){
			if([inDefaults count] > 0){
				if([[inDefaults objectAtIndex:0U] isKindOfClass:[NSNumber class]]){
					NSUInteger found = [inDefaults indexOfObjectPassingTest:^BOOL(id innerObj, NSUInteger innerIdx, BOOL *stopInner) {
						if(index == [innerObj unsignedIntegerValue])
							return YES;
						return NO;
					}];
					result = (found != NSNotFound) ? YES : NO;
				}else{
					result = [inDefaults containsObject:name];
				}
			}
		}else if([inDefaults isKindOfClass:[NSIndexSet class]]){
			result = [inDefaults containsIndex:index];
		}
	}else{
		result = NO;
	}
	return result;
}

-(void)registerWithDictionary:(NSDictionary *)regDict {
	__weak GrowlTicketDatabaseApplication *weakSelf = self;
   void (^regBlock)(void) = ^{
		
		id icon = [regDict objectForKey:GROWL_APP_ICON_DATA];
		if(icon && [icon isKindOfClass:[NSImage class]])
			icon = [(NSImage*)icon TIFFRepresentation];
		if(icon && [icon isKindOfClass:[NSData class]])
			weakSelf.iconData = icon;
		
		weakSelf.name = [regDict objectForKey:GROWL_APP_NAME];
		weakSelf.appID = [regDict objectForKey:GROWL_APP_ID];
		weakSelf.positionType = [NSNumber numberWithInteger:0];	
		weakSelf.selectedPosition = [NSNumber numberWithInteger:0];
		weakSelf.appPath = [GrowlTicketDatabaseApplication fullPathForRegDictApp:regDict];
		
		NSDictionary *humanReadableNames = [regDict objectForKey:GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES];
		NSDictionary *notificationDescriptions = [regDict objectForKey:GROWL_NOTIFICATIONS_DESCRIPTIONS];
		NSDictionary *notificationIcons = [regDict objectForKey:GROWL_NOTIFICATIONS_ICONS];
		
		//Get all the notification names and the data about them
		NSArray *allNotificationNames = [regDict objectForKey:GROWL_NOTIFICATIONS_ALL];
		NSAssert1(allNotificationNames, @"Ticket dictionaries must contain a list of all their notifications (application name: %@)", appName);
		
		id inDefaults = [regDict objectForKey:GROWL_NOTIFICATIONS_DEFAULT];
		if (!inDefaults) inDefaults = allNotificationNames;
		
		[allNotificationNames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			//Note names should ALWAYS be a string
			if (![obj isKindOfClass:[NSString class]])
				return;
			
			GrowlTicketDatabaseNotification *note = [NSEntityDescription insertNewObjectForEntityForName:@"GrowlNotificationTicket"
																										 inManagedObjectContext:[weakSelf managedObjectContext]];
			
			[note setParent:weakSelf];
			
			NSString *name = obj;
			note.name = name;
			//Set the human readable name if we were supplied one
			if([humanReadableNames objectForKey:name])
				note.humanReadableName = [humanReadableNames objectForKey:name];
			else
				note.humanReadableName = note.name;
			note.ticketDescription = [notificationDescriptions objectForKey:name];
			
			note.sticky = [NSNumber numberWithInt:NSMixedState];
			BOOL defaultEnabled = [GrowlTicketDatabaseApplication isNoteDefault:note.name
																					  inNoteArray:allNotificationNames 
																					forInDefaults:inDefaults];
			note.defaultEnabled = [NSNumber numberWithBool:defaultEnabled];
			note.enabled = note.defaultEnabled;
			
			NSData *iconData = [notificationIcons valueForKey:name];
			if(iconData && [iconData isKindOfClass:[NSImage class]])
				iconData = [(NSImage*)iconData TIFFRepresentation];
			if(iconData && [iconData isKindOfClass:[NSData class]])
				note.iconData = iconData;
		}];
	};
	if([NSThread isMainThread])
      regBlock();
   else
      [self.managedObjectContext performBlockAndWait:regBlock];
}

-(void)reregisterWithDictionary:(NSDictionary *)regDict {
	__weak GrowlTicketDatabaseApplication *weakSelf = self;
   void (^regBlock)(void) = ^{
		weakSelf.iconData = [regDict objectForKey:GROWL_APP_ICON_DATA];
		weakSelf.appID = [regDict objectForKey:GROWL_APP_ID];
		weakSelf.appPath = [GrowlTicketDatabaseApplication fullPathForRegDictApp:regDict];
		
		NSDictionary *humanReadableNames = [regDict objectForKey:GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES];
		NSDictionary *notificationDescriptions = [regDict objectForKey:GROWL_NOTIFICATIONS_DESCRIPTIONS];
		NSDictionary *notificationIcons = [regDict objectForKey:GROWL_NOTIFICATIONS_ICONS];

		//Get all the notification names and the data about them
		NSArray *allNotificationNames = [regDict objectForKey:GROWL_NOTIFICATIONS_ALL];
		NSAssert1(allNotificationNames, @"Ticket dictionaries must contain a list of all their notifications (application name: %@)", appName);
		
		id inDefaults = [regDict objectForKey:GROWL_NOTIFICATIONS_DEFAULT];
		if (!inDefaults) inDefaults = allNotificationNames;
		
		__block NSUInteger added = 0;
		NSMutableArray *newNotesArray = [NSMutableArray arrayWithCapacity:[allNotificationNames count]];
		[allNotificationNames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			if(![obj isKindOfClass:[NSString class]])
				return;
			
			GrowlTicketDatabaseNotification *note = [weakSelf notificationTicketForName:obj];
			if(!note){
				note = [NSEntityDescription insertNewObjectForEntityForName:@"GrowlNotificationTicket"
																 inManagedObjectContext:[weakSelf managedObjectContext]];
				[note setParent:weakSelf];
				
				NSString *name = obj;
				note.name = name;
				//Set the human readable name if we were supplied one
				if([humanReadableNames objectForKey:name])
					note.humanReadableName = [humanReadableNames objectForKey:name];
				else
					note.humanReadableName = note.name;
				note.ticketDescription = [notificationDescriptions objectForKey:name];
				
				note.sticky = [NSNumber numberWithInt:NSMixedState];
				BOOL defaultEnabled = [GrowlTicketDatabaseApplication isNoteDefault:note.name
																						  inNoteArray:allNotificationNames 
																						forInDefaults:inDefaults];
				note.defaultEnabled = [NSNumber numberWithBool:defaultEnabled];
				note.enabled = note.defaultEnabled;
				NSData *iconData = [notificationIcons valueForKey:name];
				if(iconData)
					note.iconData = iconData;
				
				added++;
			}else{
            BOOL defaultEnabled = [GrowlTicketDatabaseApplication isNoteDefault:note.name
                                                                    inNoteArray:allNotificationNames
                                                                  forInDefaults:inDefaults];
            note.defaultEnabled = [NSNumber numberWithBool:defaultEnabled];
            
            NSString *name = obj;
            if([humanReadableNames objectForKey:name])
               note.humanReadableName = [humanReadableNames objectForKey:name];
            else
               note.humanReadableName = note.name;
            
            NSData *iconData = [notificationIcons valueForKey:name];
            if(iconData)
               note.iconData = iconData;
			}
			[newNotesArray addObject:note];
		}];
		
		NSMutableArray *toRemove = [NSMutableArray array];
		[weakSelf.children enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
			if(![newNotesArray containsObject:obj])
				[toRemove addObject:obj];
		}];

		//NSLog(@"During reregistration, added: %lu notes, removed: %lu notes", added, [toRemove count]);
		[toRemove enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			[[weakSelf managedObjectContext] deleteObject:obj];
		}];
	};
	if([NSThread isMainThread])
      regBlock();
   else
      [self.managedObjectContext performBlockAndWait:regBlock];
}

- (NSDictionary*)registrationFormatDictionary {
	__weak GrowlTicketDatabaseApplication *weakSelf = self;
	__block NSMutableDictionary *regDict = nil;
   void (^regDictBlock)(void) = ^{
		NSUInteger noteCount = [weakSelf.children count];
		__weak NSMutableArray *allNotificationNames = [NSMutableArray arrayWithCapacity:noteCount];
		__weak NSMutableArray *defaultNotifications = [NSMutableArray arrayWithCapacity:noteCount];
		__weak NSMutableDictionary *humanReadableNames = [NSMutableDictionary dictionaryWithCapacity:noteCount];
		__weak NSMutableDictionary *notificationDescriptions = [NSMutableDictionary dictionaryWithCapacity:noteCount];
		
		[weakSelf.children enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
			NSString *noteName = [obj name];
			[allNotificationNames addObject:noteName];
			[humanReadableNames setObject:[obj humanReadableName] forKey:noteName];
			if([[obj defaultEnabled] boolValue])
				[defaultNotifications addObject:noteName];
			if([obj ticketDescription])
				[notificationDescriptions setObject:[obj ticketDescription] forKey:noteName];
		}];
		
		regDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:weakSelf.name, GROWL_APP_NAME,
					  allNotificationNames, GROWL_NOTIFICATIONS_ALL,
					  defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
					  humanReadableNames, GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES,
					  weakSelf.iconData, GROWL_APP_ICON_DATA, nil];
		
		if ([weakSelf.parent name] && ![[weakSelf.parent name] isLocalHost])
			[regDict setObject:[weakSelf.parent name] forKey:GROWL_NOTIFICATION_GNTP_SENT_BY];
      
		if (notificationDescriptions && [notificationDescriptions count] > 0)
			[regDict setObject:notificationDescriptions forKey:GROWL_NOTIFICATIONS_DESCRIPTIONS];
		
		if (weakSelf.appID)
			[regDict setObject:weakSelf.appID forKey:GROWL_APP_ID];
	};
	
   if([NSThread isMainThread])
      regDictBlock();
   else
      [self.managedObjectContext performBlockAndWait:regDictBlock];
	
   return regDict;
}

-(GrowlTicketDatabaseNotification*)notificationTicketForName:(NSString*)noteName {
   __block GrowlTicketDatabaseNotification* note = nil;
	__weak GrowlTicketDatabaseApplication *weakSelf = self;
   void (^noteBlock)(void) = ^{
		[weakSelf.children enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
			if([[obj name] isEqualToString:noteName]){
				note = obj;
				*stop = YES;
			}
		}];
	};
	if([NSThread isMainThread])
		noteBlock();
	else
		[self.managedObjectContext performBlockAndWait:noteBlock];

   return note;
}

- (NSComparisonResult) caseInsensitiveCompare:(GrowlTicketDatabaseApplication *)aTicket {
	__block NSComparisonResult result = NSOrderedSame;
	__weak GrowlTicketDatabaseApplication *weakSelf = self;
   void (^compareBlock)(void) = ^{
		NSString *selfHost = weakSelf.parent.name;
		NSString *aTicketHost = aTicket.parent.name;
		if(!selfHost && !aTicketHost){
			result = [[weakSelf name] caseInsensitiveCompare:[aTicket name]];
		}else if(selfHost && !aTicketHost){
			result = NSOrderedDescending;
		}else if(!selfHost && aTicketHost){
			result = NSOrderedAscending;
		}else { // if(selfHost && aTicketHost){
			if([selfHost caseInsensitiveCompare:aTicketHost] == NSOrderedSame)
				result = [[weakSelf name] caseInsensitiveCompare:[aTicket name]];
			else
				result = [selfHost caseInsensitiveCompare:aTicketHost];
		}
	};	
	if([NSThread isMainThread])
		compareBlock();
	else
		[self.managedObjectContext performBlockAndWait:compareBlock];
	return result;
}


@end
