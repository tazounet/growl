//
//  GrowlPluginPreferencePane.h
//  Growl
//
//  Created by Daniel Siemer on 3/3/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@interface GrowlPluginPreferencePane : NSPreferencePane

@property (nonatomic, strong) NSMutableDictionary *configuration;
@property (nonatomic, readonly) NSString *configurationID;

-(void)setConfigurationValue:(id)value forKey:(NSString*)key;
-(void)updateConfigurationValues;
-(NSColor *) loadColor:(NSString *)key defaultColor:(NSColor *)defaultColor;

-(void)_setDisplayName:(NSString*)displayName;
-(NSSet*)bindingKeys;
-(void)setPluginConfiguration:(NSManagedObject *)plugin;

@end
