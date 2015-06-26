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

- (id)initWithNibName:(NSString *)nibNameOrNil 
               bundle:(NSBundle *)nibBundleOrNil
          forPrefPane:(GrowlPreferencePane*)aPrefPane;

+ (NSString*)nibName;

- (void)viewWillLoad;
- (void)viewDidLoad;
- (void)viewWillUnload;
- (void)viewDidUnload;

@end
