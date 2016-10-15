//
//	GrowlNotification.m
//	Growl
//
//	Copyright 2005-2011 The Growl Project. All rights reserved.
//

#import <GrowlPlugins/GrowlNotification.h>
#import "GrowlDefines.h"

@implementation GrowlNotification

@synthesize name;
@synthesize applicationName;
@synthesize title;
@synthesize messageText;
@synthesize icon;
@synthesize identifier;
@synthesize sticky;
@synthesize priority;
@synthesize auxiliaryDictionary;
@synthesize configurationDict;

+ (GrowlNotification *) notificationWithDictionary:(NSDictionary *)dict
                                 configurationDict:(NSDictionary*)config {
	return [[self alloc] initWithDictionary:dict configurationDict:config];
}

- (GrowlNotification *) initWithDictionary:(NSDictionary *)dict
                         configurationDict:(NSDictionary *)config
{
	if ((self = [self initWithName:dict[GROWL_NOTIFICATION_NAME]
                   applicationName:dict[GROWL_APP_NAME]
                             title:dict[GROWL_NOTIFICATION_TITLE]
                       description:dict[GROWL_NOTIFICATION_DESCRIPTION]
                configureationDict:config])) {
		NSMutableDictionary *mutableDict = [dict mutableCopy];
		[mutableDict removeObjectsForKeys:[GrowlNotification standardKeys].allObjects];
		if (mutableDict.count)
			self.auxiliaryDictionary = mutableDict;
	}
	return self;
}

- (GrowlNotification *) initWithName:(NSString *)newName
                     applicationName:(NSString *)newAppName
                               title:(NSString *)newTitle
                         description:(NSString *)newDesc
                  configureationDict:(NSDictionary *)config
{
	if ((self = [self init])) {
		name            = [newName      copy];
		applicationName = [newAppName   copy];
		
		title           = [newTitle     copy];
		messageText     = [newDesc      copy];
		self.configurationDict = config;
	}
	return self;
}


#pragma mark -

+ (NSSet *) standardKeys {
	static NSSet *standardKeys = nil;

	if (!standardKeys) {
		standardKeys = [[NSSet alloc] initWithObjects:
			GROWL_NOTIFICATION_NAME,
			GROWL_APP_NAME,
			GROWL_NOTIFICATION_TITLE,
			GROWL_NOTIFICATION_DESCRIPTION,
			nil];
	}

	return standardKeys;
}

- (NSDictionary *) dictionaryRepresentation {
	return [self dictionaryRepresentationWithKeys:nil];
}
- (NSDictionary *) dictionaryRepresentationWithKeys:(NSSet *)keys {
	NSMutableDictionary *dict = nil;

	if (!keys) {
		//Try cache first.
		if (cachedDictionaryRepresentation)
			return cachedDictionaryRepresentation;

		//No joy - create it.
		dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
			name,            GROWL_NOTIFICATION_NAME,
			applicationName, GROWL_APP_NAME,
			title,           GROWL_NOTIFICATION_TITLE,
			messageText,     GROWL_NOTIFICATION_DESCRIPTION,
			nil];

		for (id key in auxiliaryDictionary)
			if (!dict[key])
				dict[key] = auxiliaryDictionary[key];
	} else {
		//Only include keys in the set.
		dict = [[NSMutableDictionary alloc] initWithCapacity:keys.count];

		if ([keys containsObject:GROWL_NOTIFICATION_NAME])
			dict[GROWL_NOTIFICATION_NAME] = name;
		if ([keys containsObject:GROWL_APP_NAME])
			dict[GROWL_APP_NAME] = applicationName;
		if ([keys containsObject:GROWL_NOTIFICATION_TITLE])
			dict[GROWL_NOTIFICATION_TITLE] = title;
		if ([keys containsObject:GROWL_NOTIFICATION_DESCRIPTION])
			dict[GROWL_NOTIFICATION_DESCRIPTION] = messageText;

		for (id key in auxiliaryDictionary)
			if ([keys containsObject:key] && !dict[key])
				dict[key] = auxiliaryDictionary[key];
	}

	NSDictionary *result = [NSDictionary dictionaryWithDictionary:dict];

	if (!keys) {
		//Update our cache.
		 cachedDictionaryRepresentation = nil;

		cachedDictionaryRepresentation = result;
	}

	return result;
}

#pragma mark -

- (NSString *) notificationDescription {
	return self.messageText;
}

- (void) setAuxiliaryDictionary:(NSDictionary *)newAuxDict {
	 auxiliaryDictionary = [newAuxDict copy];

	/*-dictionaryRepresentationWithKeys:nil depends on the auxiliary dictionary.
	 *so if the auxiliary dictionary changes, we must dirty the cache used by
	 *	-dictionaryRepresentation.
	 */
	 cachedDictionaryRepresentation = nil;
}

@end
