//
//  GrowlPluginPreferenceStrings.h
//  Growl
//
//  Created by Daniel Siemer on 1/30/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

/* FOR GROWL DEVELOPED COCOA PLUGINS ONLY AT THIS TIME, NOT STABLE */

#import <Foundation/Foundation.h>

@interface GrowlPluginPreferenceStrings : NSObject

@property (nonatomic, strong) NSString *growlDisplayOpacity;
@property (nonatomic, strong) NSString *growlDisplayDuration;

@property (nonatomic, strong) NSString *growlDisplayPriority;
@property (nonatomic, strong) NSString *growlDisplayPriorityVeryLow;
@property (nonatomic, strong) NSString *growlDisplayPriorityModerate;
@property (nonatomic, strong) NSString *growlDisplayPriorityNormal;
@property (nonatomic, strong) NSString *growlDisplayPriorityHigh;
@property (nonatomic, strong) NSString *growlDisplayPriorityEmergency;

@property (nonatomic, strong) NSString *growlDisplayTextColor;
@property (nonatomic, strong) NSString *growlDisplayBackgroundColor;

@property (nonatomic, strong) NSString *growlDisplayLimitLines;
@property (nonatomic, strong) NSString *growlDisplayScreen;
@property (nonatomic, strong) NSString *growlDisplaySize;
@property (nonatomic, strong) NSString *growlDisplaySizeNormal;
@property (nonatomic, strong) NSString *growlDisplaySizeLarge;
@property (nonatomic, strong) NSString *growlDisplaySizeSmall;

@property (nonatomic, strong) NSString *growlDisplayFloatingIcon;

@property (nonatomic, strong) NSString *effectLabel;
@property (nonatomic, strong) NSString *slideEffect;
@property (nonatomic, strong) NSString *fadeEffect;

@end
