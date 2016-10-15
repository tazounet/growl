//
//  GrowlFirstLaunchWindowController.m
//  Growl
//
//  Created by Daniel Siemer on 8/17/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlFirstLaunchWindowController.h"
#import "GrowlApplicationController.h"
#import "GrowlPreferencesController.h"
#import "GrowlVersionUtilities.h"
#import "GrowlPathUtilities.h"
#import "GrowlMenu.h"

typedef void(^GrowlFirstLaunchAction)(void);

@implementation GrowlFirstLaunchWindowController

@synthesize windowTitle;
@synthesize textBoxString;
@synthesize webView;
@synthesize actionButtonTitle;
@synthesize continueButtonTitle;

@synthesize actionEnabled;

@synthesize current;

@synthesize launchViews;
@synthesize progressIndicator;
@synthesize progressLabel;

+(BOOL)previousVersionOlder
{
   NSString *current = @"2.1.2";//[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
   NSString *previous = [[GrowlPreferencesController sharedController] objectForKey:LastKnownVersionKey];
   return (!previous || compareVersionStrings(previous, current) == kCFCompareLessThan);
}

+(BOOL)shouldRunFirstLaunch
{
   GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
   if(![preferences objectForKey:GrowlFirstLaunch] || [preferences boolForKey:GrowlFirstLaunch])
      return YES;
   

   if([GrowlFirstLaunchWindowController previousVersionOlder]){
      return YES;
   }
   return NO;
}

- (instancetype)init
{
    if ((self = [super initWithWindowNibName:@"FirstLaunchWindow" owner:self])) {
        // Initialization code here.
       self.windowTitle = NSLocalizedString(@"Welcome to Growl!", @"");
       self.continueButtonTitle = NSLocalizedString(@"Continue", @"Continue button title");
       
       GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
       self.current = 0;
       
       NSMutableArray *views = [NSMutableArray array];
      
		 NSString *welcomeString = [[NSBundle mainBundle] URLForResource:@"Welcome" withExtension:@"html"].absoluteString;
       NSDictionary *welcomeDict = @{@"textBody": welcomeString};
       [views addObject:welcomeDict];
       
		 NSString *whatsNewString = [[NSBundle mainBundle] URLForResource:@"WhatsNew" withExtension:@"html"].absoluteString;
       NSDictionary *whatsNewDict = @{@"textBody": whatsNewString};
       [views addObject:whatsNewDict];
       
       if(!preferences.allowStartAtLogin) {
         GrowlFirstLaunchAction loginBlock = [^{
             GrowlPreferencesController *prefs = [GrowlPreferencesController sharedController];
             [prefs setShouldStartGrowlAtLogin:YES];
             [prefs setAllowStartAtLogin:YES];
          } copy];
          
			 NSString *loginString = [[NSBundle mainBundle] URLForResource:@"StartAtLogin" withExtension:@"html"].absoluteString;
          NSDictionary *loginDict = @{@"textBody": loginString,
                                      @"actionBlock": loginBlock,
                                      @"actionTitle": FirstLaunchStartGrowlButton};
          [views addObject:loginDict];
       }
       if(![[GrowlPathUtilities runningHelperAppBundle] isEqual:[NSBundle mainBundle]]) {
          GrowlFirstLaunchAction oldBlock = [^{
				 [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://growl.info/documentation/growl-package-removal.php#1.2easy"]];
          } copy];
			 NSString *oldString = [[NSBundle mainBundle] URLForResource:@"OldGrowl" withExtension:@"html"].absoluteString;
          NSDictionary *oldDict = @{@"textBody": oldString,
                                    @"actionBlock": oldBlock,
                                    @"actionTitle": FirstLaunchOldGrowlButton};
          [views addObject:oldDict];
       }
       
       self.launchViews = [views copy];
    }
    
    return self;
}

-(void)awakeFromNib
{
   progressIndicator.maxValue = launchViews.count;
   [self showCurrent];
}


-(void)close
{
   NSString *currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
   [[GrowlPreferencesController sharedController] setObject:currentVersion forKey:LastKnownVersionKey];
   [[GrowlApplicationController sharedController] performSelector:@selector(firstLaunchClosed) withObject:nil afterDelay:1.0];
   [super close];
}

-(void)showCurrent
{
   self.progressLabel = [NSString stringWithFormat:@"%lu/%lu", current + 1, launchViews.count];
   progressIndicator.doubleValue = (double)(current + 1);
   if(current == launchViews.count - 1){
      self.continueButtonTitle = NSLocalizedString(@"Done", @"Continue button title when done");
   }
   
   if([launchViews[current] valueForKey:@"actionBlock"]){
      self.actionEnabled = YES;
      self.actionButtonTitle = [launchViews[current] valueForKey:@"actionTitle"];
   }
   
   self.textBoxString = [launchViews[current] valueForKey:@"textBody"];
	(self.webView).mainFrameURL = self.textBoxString;
}

-(IBAction)nextPage:(id)sender
{
   self.current++;
   if(current >= launchViews.count){
      [self close];
      return;
   }
   [self showCurrent];
}

-(IBAction)actionButton:(id)sender
{
   if([launchViews[current] valueForKey:@"actionBlock"]){
      GrowlFirstLaunchAction action = [launchViews[current] valueForKey:@"actionBlock"];
      action();
   }
}

- (void)webView:(WebView *)webView
decidePolicyForNavigationAction:(NSDictionary *)actionInformation
		  request:(NSURLRequest *)request
			 frame:(WebFrame *)frame
decisionListener:(id < WebPolicyDecisionListener >)listener
{
	NSString *host = request.URL.host;
	if (host) {
		[[NSWorkspace sharedWorkspace] openURL:request.URL];
	} else {
		[listener use];
	}
}

@end
