//
//  GrowlPrefsViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/9/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GrowlPreferencePane;
@class GrowlPreferencesController;

@interface GrowlPrefsViewController : NSViewController

@property (nonatomic, strong) GrowlPreferencePane *prefPane;
@property (nonatomic, weak) GrowlPreferencesController *preferencesController;
@property (nonatomic, strong) NSTimer *releaseTimer;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil 
               bundle:(NSBundle *)nibBundleOrNil
          forPrefPane:(GrowlPreferencePane*)aPrefPane NS_DESIGNATED_INITIALIZER;

+ (NSString*)nibName;

- (void)viewWillLoad;
- (void)viewDidLoad;
- (void)viewWillUnload;
- (void)viewDidUnload;

@end
