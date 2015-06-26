//
//  GrowlRollupPrefsViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/11/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"

@class SRRecorderControl;
@class GrowlPreferencesController;

@interface GrowlRollupPrefsViewController : GrowlPrefsViewController

@property (nonatomic, strong) IBOutlet SRRecorderControl *recorderControl;
@property (nonatomic, strong) NSString *rollupEnabledTitle;
@property (nonatomic, strong) NSString *rollupAutomaticTitle;
@property (nonatomic, strong) NSString *rollupAllTitle;
@property (nonatomic, strong) NSString *rollupLoggedTitle;
@property (nonatomic, strong) NSString *showHideTitle;

@property (nonatomic, strong) NSString *pulseMenuItemTitle;
@property (nonatomic, strong) NSString *idleDetectionBoxTitle;
@property (nonatomic, strong) NSString *idleAfterTitle;
@property (nonatomic, strong) NSString *secondsTitle;
@property (nonatomic, strong) NSString *minutesTitle;
@property (nonatomic, strong) NSString *hoursTitle;
@property (nonatomic, strong) NSString *whenScreenSaverActiveTitle;
@property (nonatomic, strong) NSString *whenScreenLockedTitle;

@end
