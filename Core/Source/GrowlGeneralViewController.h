//
//  GrowlGeneralViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/9/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"

@class GrowlPositionPicker, GrowlOnSwitch;
@class SRRecorderControl;

@interface GrowlGeneralViewController : GrowlPrefsViewController

@property (nonatomic, weak) IBOutlet GrowlPositionPicker *globalPositionPicker;
@property (nonatomic, weak) IBOutlet GrowlOnSwitch *startAtLoginSwitch;
@property (weak) IBOutlet SRRecorderControl *recorderControl;
@property (nonatomic, weak) IBOutlet NSImageView *growlClawLogo;
@property (nonatomic, weak) IBOutlet GrowlOnSwitch *useAppleNotificationCenterSwitch;
@property (nonatomic, weak) IBOutlet NSTextField *useAppleNotificationCenterLabelField;
@property (nonatomic, weak) IBOutlet NSTextField *useAppleNotificationCenterExplanationField;
@property (nonatomic, weak) IBOutlet NSButton *additionalDownloadsButton;

@property (nonatomic, strong) NSString *closeAllNotificationsTitle;
@property (nonatomic, strong) NSString *additionalDownloadsButtonTitle;
@property (nonatomic, strong) NSString *startGrowlAtLoginLabel;
@property (nonatomic, strong) NSString *useAppleNotificationCenterLabel;
@property (nonatomic, strong) NSString *appleNotificationCenterExplanation;
@property (nonatomic, strong) NSString *defaultStartingPositionLabel;
@property (nonatomic, strong) NSArray *iconMenuOptionsList;

@property (nonatomic, assign) BOOL showRulesUI;

-(IBAction)startGrowlAtLogin:(id)sender;
-(IBAction)useAppleNotificationCenter:(id)sender;

@end
