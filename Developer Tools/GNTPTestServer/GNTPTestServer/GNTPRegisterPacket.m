//
//  GNTPRegisterPacket.m
//  GNTPTestServer
//
//  Created by Daniel Siemer on 7/4/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "GNTPRegisterPacket.h"
#import "GrowlDefines.h"
#import "GrowlDefinesInternal.h"
#import "GrowlImageAdditions.h"
#import "GNTPUtilities.h"

@interface GNTPRegisterPacket ()

@property (nonatomic, assign) NSUInteger totalNotifications;
@property (nonatomic, assign) NSUInteger readNotifications;

@end

@implementation GNTPRegisterPacket

@synthesize totalNotifications = _totalNotifications;
@synthesize readNotifications = _readNotifications;
@synthesize notificationDicts = _notificationDicts;

+(NSMutableDictionary*)gntpDictFromGrowlDict:(NSDictionary *)dict {
	NSMutableDictionary *converted = [super gntpDictFromGrowlDict:dict];
	NSArray *allNotes = [dict valueForKey:GROWL_NOTIFICATIONS_ALL];
	NSArray *defaultNotes = [dict valueForKey:GROWL_NOTIFICATIONS_DEFAULT];
	BOOL useNumberDefaults = defaultNotes.count > 0 ? [defaultNotes[0] isKindOfClass:[NSNumber class]] : NO; //If count is 0, doesn't really matter
	NSDictionary *noteIcons = [dict valueForKey:GROWL_NOTIFICATIONS_ICONS];
	NSDictionary *humanReadableNames = [dict valueForKey:GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES];
	NSDictionary *descriptions = [dict valueForKey:GROWL_NOTIFICATIONS_DESCRIPTIONS];
	
	NSMutableArray *convertedNotes = [NSMutableArray arrayWithCapacity:allNotes.count];
	[allNotes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSMutableDictionary *noteDict = [NSMutableDictionary dictionary];
		noteDict[GrowlGNTPNotificationName] = obj;
		
		id defaultObj = useNumberDefaults ? @(idx) : obj;
		if([defaultNotes containsObject:defaultObj]){
			noteDict[GrowlGNTPNotificationEnabled] = @"Yes";
		}else{
			noteDict[GrowlGNTPNotificationEnabled] = @"No";
		}
		
		id iconObject = noteIcons[obj];
		if(iconObject){
			if([iconObject isKindOfClass:[NSImage class]])
				iconObject = [iconObject PNGRepresentation];
			//Add to the data blocks
			NSString *dataIdentifier = [GNTPPacket identifierForBinaryData:iconObject];
			NSMutableDictionary *dataDict = converted[@"GNTPDATABLOCKS"];
			if(!dataDict){
				dataDict = [NSMutableDictionary dictionary];
				converted[@"GNTPDATABLOCKS"] = dataDict;
			}
			dataDict[dataIdentifier] = iconObject;
			noteDict[GrowlGNTPNotificationIcon] = [NSString stringWithFormat:@"x-growl-resource://%@", dataIdentifier];
		}
		if(humanReadableNames[obj])
			noteDict[GrowlGNTPNotificationDisplayName] = humanReadableNames[obj];
		if(descriptions[obj])
			noteDict[@"X-Notification-Description"] = descriptions[obj];
		
		[convertedNotes addObject:noteDict];
	 }];
	converted[GrowlGNTPNotificationCountHeader] = [NSString stringWithFormat:@"%lu", allNotes.count];
	converted[GROWL_NOTIFICATIONS_ALL] = convertedNotes;
	return converted;
}

+(NSString*)headersForGNTPDictionary:(NSDictionary *)dict {
	NSMutableString *headers = [[super headersForGNTPDictionary:dict] mutableCopy];
	NSArray *allNotes = dict[GROWL_NOTIFICATIONS_ALL];
	[allNotes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		//Seperate our the notes from each other
		[headers appendString:@"\r\n"];
		[obj enumerateKeysAndObjectsUsingBlock:^(id key, id innerObj, BOOL *innerStop) {
			[headers appendFormat:@"%@: %@\r\n", key, innerObj];
		}];
	}];
	return [headers copy];
}

-(instancetype)init {
	if((self = [super init])){
		_totalNotifications = 0;
		_readNotifications = 0;
		_notificationDicts = [[NSMutableArray alloc] init];
	}
	return self;
}

-(BOOL)validateNoteDictionary:(NSDictionary*)noteDict {
	return [noteDict valueForKey:GrowlGNTPNotificationName] != nil;
}

-(NSInteger)parseDataBlock:(NSData *)data
{
	NSInteger result = 0;
	switch (self.state) {
		case 101:
		{
			//Reading in notifications
			//break it down
			//No need to handle the extra CLRF's after the last line
			NSString *noteHeaderBlock = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			
			NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
			[GNTPUtilities enumerateHeaders:noteHeaderBlock
									 withBlock:^BOOL(NSString *headerKey, NSString *headerValue) {
										 if([headerValue isKindOfClass:[NSString class]]) {
											 NSRange resourceRange = [headerValue rangeOfString:@"x-growl-resource://"];
											 if(resourceRange.location != NSNotFound && resourceRange.location == 0){
												 //This is a resource ID; add the ID to the array of waiting IDs
												 NSString *dataBlockID = [headerValue substringFromIndex:resourceRange.location + resourceRange.length];
												 [self.dataBlockIdentifiers addObject:dataBlockID];
											 }
										 }
										 dictionary[headerKey] = headerValue;
										 return NO;
									 }];
			//validate
			if(![self validateNoteDictionary:dictionary]){
				if(dictionary.allValues.count > 0)
					NSLog(@"Unable to validate notification %@ in registration packet", dictionary);
				else
					NSLog(@"Empty note dict misread?");
			}else{
				[self.notificationDicts addObject:dictionary];
			}
			//Even if we can't validate it, we did read it, skip it and move on
			self.readNotifications++;
			
			if(self.totalNotifications - self.readNotifications == 0) {
				if((self.dataBlockIdentifiers).count > 0)
					self.state = 1;
				else{
					self.state = 999;
				}
			}
			break;
		}
		default:
			[super parseDataBlock:data];
			break;
	}
	if(self.totalNotifications == 0)
		result = -1;
	else
		result = (self.totalNotifications - self.readNotifications) + (self.dataBlockIdentifiers).count;
	
	if(self.totalNotifications - self.readNotifications > 0) {
		self.state = 101; //More notifications to read, read them, otherwise state is controlled by the call to super parseDataBlock
	}
	
	return result;
}

-(void)parseHeaderKey:(NSString *)headerKey value:(NSString *)stringValue
{
	if([headerKey caseInsensitiveCompare:GrowlGNTPNotificationCountHeader] == NSOrderedSame){
		self.totalNotifications = stringValue.integerValue;
		if(self.totalNotifications == 0)
			NSLog(@"Error parsing %@ as an integer for a number of notifications", stringValue);
	}else{
		[super parseHeaderKey:headerKey value:stringValue];
	}
}

-(void)receivedResourceDataBlock:(NSData *)data forIdentifier:(NSString *)identifier {
	[self.notificationDicts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		//check the icon, its the main thing that will need replacing
		id icon = obj[GrowlGNTPNotificationIcon];
		if([icon isKindOfClass:[NSString class]] && [icon rangeOfString:identifier].location != NSNotFound){
			//Found an icon that matches the ID
			obj[identifier] = data;
		}
	}];
	//pass it back up to super in case there are things that need replacing up there
	[super receivedResourceDataBlock:data forIdentifier:identifier];
}

-(BOOL)validate {
	return super.validate && self.totalNotifications == (self.notificationDicts).count;
}

-(NSDictionary*)convertedGrowlDict {
	NSMutableDictionary *convertedDict = super.convertedGrowlDict;
	NSMutableArray *notificationNames = [NSMutableArray arrayWithCapacity:(self.notificationDicts).count];
	NSMutableDictionary *displayNames = [NSMutableDictionary dictionary];
	//2.0 framework should be upgraded to include descriptions
	NSMutableDictionary *notificationDescriptions = [NSMutableDictionary dictionary];
	NSMutableArray *enabledNotes = [NSMutableArray array];
	//Should really upgrade 2.0 to support note icons during registration;
	NSMutableDictionary *noteIcons = [NSMutableDictionary dictionary];
	[self.notificationDicts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSString *notificationName = obj[GrowlGNTPNotificationName];
		if(notificationName){
			[notificationNames addObject:notificationName];
			
			NSString *displayName = obj[GrowlGNTPNotificationDisplayName];
			NSString *enabledString = obj[GrowlGNTPNotificationEnabled];
			NSString *description = obj[@"X-Notification-Description"];
			id icon = obj[GrowlGNTPNotificationIcon];
			NSData *iconData = nil;
			if(icon)
				iconData = [GNTPPacket convertedDataForIconObject:icon];
						
			if(displayName)
				displayNames[notificationName] = displayName;
			if(description)
				notificationDescriptions[notificationName] = description;
			if(enabledString && 
				([enabledString caseInsensitiveCompare:@"Yes"] == NSOrderedSame || 
				[enabledString caseInsensitiveCompare:@"True"] == NSOrderedSame))
			{
				[enabledNotes addObject:notificationName];
			}
			if(iconData)
				noteIcons[notificationName] = iconData;
		}else{
			NSLog(@"Unable to process note without name!");
		}
	}];
	
   if(!convertedDict[GROWL_APP_ICON_DATA]){
      convertedDict[GROWL_APP_ICON_DATA] = [NSImage imageNamed:NSImageNameNetwork].TIFFRepresentation;
   }
   
	convertedDict[GROWL_NOTIFICATIONS_ALL] = notificationNames;
	if(enabledNotes.count > 0)
		convertedDict[GROWL_NOTIFICATIONS_DEFAULT] = enabledNotes;
	if(displayNames.allValues.count > 0)
		convertedDict[GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES] = displayNames;
	if(notificationDescriptions.allValues.count > 0)
		convertedDict[GROWL_NOTIFICATIONS_DESCRIPTIONS] = notificationDescriptions;
	if(noteIcons.allValues.count > 0)
		convertedDict[GROWL_NOTIFICATIONS_ICONS] = noteIcons;
	return convertedDict;
}

@end
