//
//  GrowlFirstLaunchWindowController.h
//  Growl
//
//  Created by Daniel Siemer on 8/17/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlFirstLaunchStrings.h"
#import <WebKit/WebKit.h>

@interface GrowlFirstLaunchWindowController : NSWindowController <NSWindowDelegate>

@property (nonatomic, strong) NSString *windowTitle;
@property (nonatomic, strong) NSString *textBoxString;
@property (nonatomic, weak) IBOutlet WebView *webView;
@property (nonatomic, strong) NSString *actionButtonTitle;
@property (nonatomic, strong) NSString *continueButtonTitle;

@property (nonatomic) BOOL actionEnabled;

@property (nonatomic) NSUInteger current;

@property (nonatomic, strong) NSArray *launchViews;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (nonatomic, strong) NSString *progressLabel;

+(BOOL)shouldRunFirstLaunch;

-(void)showCurrent;
-(IBAction)nextPage:(id)sender;
-(IBAction)actionButton:(id)sender;

@end
