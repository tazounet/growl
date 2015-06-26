//
//  GrowlAboutViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/9/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"
#import <WebKit/WebKit.h>

@interface GrowlAboutViewController : GrowlPrefsViewController

@property (nonatomic, weak) IBOutlet NSTextField *aboutVersionString;
//@property (nonatomic, assign) IBOutlet NSTextView *aboutBoxTextView;
@property (nonatomic, weak) IBOutlet WebView *aboutWebView;

@property (nonatomic, strong) NSString *bugSubmissionLabel;
@property (nonatomic, strong) NSString *growlWebsiteLabel;

- (void) setupAboutTab;
- (IBAction) openGrowlWebSite:(id)sender;
- (IBAction) openGrowlBugSubmissionPage:(id)sender;

@end
