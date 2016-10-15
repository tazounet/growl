//
//  GrowlPreferencePane.m
//  Growl
//
//  Created by Karl Adam on Wed Apr 21 2004.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "GrowlPreferencePane.h"
#import "GrowlPreferencesController.h"
#import "GrowlDefinesInternal.h"
#import "GrowlDefines.h"
#import "GrowlPluginController.h"
#import "GrowlNotificationDatabase.h"

#import "GrowlPrefsViewController.h"
#import "GrowlGeneralViewController.h"
#import "GrowlApplicationsViewController.h"
#import "GrowlDisplaysViewController.h"
#import "GrowlServerViewController.h"
#import "GrowlAboutViewController.h"
#import "GrowlHistoryViewController.h"
#import "GrowlRollupPrefsViewController.h"

@interface GrowlPreferencePane ()

@property (nonatomic, assign) ProcessSerialNumber previousPSN;

@end

@implementation GrowlPreferencePane
@synthesize networkAddressString;
@synthesize currentViewController;
@synthesize prefViewControllers;

@synthesize settingsWindowTitle;
@synthesize generalItem;
@synthesize applicationsItem;
@synthesize displaysItem;
@synthesize networkItem;
@synthesize rollupItem;
@synthesize historyItem;
@synthesize aboutItem;

@synthesize previousPSN;

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
   
}

- (instancetype)initWithWindowNibName:(NSString *)windowNibName {
   if((self = [super initWithWindowNibName:windowNibName])){
      self.settingsWindowTitle = NSLocalizedString(@"Preferences", @"Preferences window title");
   }
   return self;
}

- (void) awakeFromNib {
   [generalItem setLabel:NSLocalizedString(@"General", @"General prefs tab title")];
   [applicationsItem setLabel:NSLocalizedString(@"Applications", @"Application prefs tab title")];
   [displaysItem setLabel:NSLocalizedString(@"Displays", @"Display prefs tab title")];
   [networkItem setLabel:NSLocalizedString(@"Network", @"Network prefs tab title")];
   [rollupItem setLabel:NSLocalizedString(@"Rollup", @"Rollup prefs tab title")];
   [historyItem setLabel:NSLocalizedString(@"History", @"History prefs tab title")];
   [aboutItem setLabel:NSLocalizedString(@"About", @"About prefs tab title")];

    firstOpen = YES;
    (self.window).collectionBehavior = NSWindowCollectionBehaviorMoveToActiveSpace;
    
    preferencesController = [GrowlPreferencesController sharedController];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(reloadPreferences:) name:GrowlPreferencesChanged object:nil];

    [self reloadPreferences:nil];
}

- (void)showWindow:(id)sender
{   
    [toolbar setVisible:YES];
    
    [super showWindow:sender];
    
    if(!firstOpen){
        if([currentViewController respondsToSelector:@selector(viewWillLoad)])
            [currentViewController viewWillLoad];
        if([currentViewController respondsToSelector:@selector(viewDidLoad)])
            [currentViewController viewDidLoad];
    }
    firstOpen = NO;
    
    // Tweak for menu bar
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSRunningApplication * app in [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.dock"]) {
            [app activateWithOptions:NSApplicationActivateIgnoringOtherApps];
            break;
        }
        [self performSelector:@selector(showWindowStep2) withObject:nil afterDelay:0.1];
    });
}

- (void)showWindowStep2
{
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    TransformProcessType(&psn, kProcessTransformToForegroundApplication);
    
    [self performSelector:@selector(showWindowStep3) withObject:nil afterDelay:0.1];
}

- (void)showWindowStep3
{
    [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];
    if(!(self.window).visible) {
        [self.window center];
        [self.window setFrameAutosaveName:@"HWGrowlerPrefsWindowFrame"];
        [self.window setFrameUsingName:@"HWGrowlerPrefsWindowFrame" force:YES];
    }
    
    [self.window makeKeyAndOrderFront:nil];
}

- (void)windowWillClose:(NSNotification *)notification
{
    if([currentViewController respondsToSelector:@selector(viewWillUnload)])
        [currentViewController viewWillUnload];
    
    //This should be seperate when the window has actually closed, but eh
    if([currentViewController respondsToSelector:@selector(viewDidUnload)])
        [currentViewController viewDidUnload];
    
    if(preferencesController.menuState == GrowlNoMenu || preferencesController.menuState == GrowlStatusMenu){
        dispatch_async(dispatch_get_main_queue(), ^{
            ProcessSerialNumber psn = { 0, kCurrentProcess };
            TransformProcessType(&psn, kProcessTransformToUIElementApplication);
        });
    }
}

#pragma mark -

/*!
 * @brief Returns the bundle version of the Growl.prefPane bundle.
 */
- (NSString *) bundleVersion {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
}


/*!
 * @brief Called when a GrowlPreferencesChanged notification is received.
 */
- (void) reloadPreferences:(NSNotification *)notification {
	@autoreleasepool{
        id object = notification.object;
        if(!object || [object isEqualToString:GrowlSelectedPrefPane])
            [self setSelectedTab:preferencesController.selectedPreferenceTab];
	}
}

#pragma mark -
#pragma mark Bindings accessors (not for programmatic use)

- (GrowlPluginController *) pluginController {
	if (!pluginController)
		pluginController = [GrowlPluginController sharedController];

	return pluginController;
}
- (GrowlPreferencesController *) preferencesController {
	if (!preferencesController)
		preferencesController = [GrowlPreferencesController sharedController];

	return preferencesController;
}

#pragma mark Toolbar support

-(void)setSelectedTab:(NSUInteger)tab
{
   toolbar.selectedItemIdentifier = [NSString stringWithFormat:@"%lu", tab];
      
   Class newClass;
    
   switch (tab) {
      case 0:
         newClass = [GrowlGeneralViewController class];
         break;
      case 1:
         newClass = [GrowlApplicationsViewController class];
         break;
      case 2:
         newClass = [GrowlDisplaysViewController class];
         break;
      case 3:
         newClass = [GrowlServerViewController class];
         break;
      case 4:
         newClass = [GrowlRollupPrefsViewController class];
         break;
      case 5:
         newClass = [GrowlHistoryViewController class];
         break;
      case 6:
         newClass = [GrowlAboutViewController class];
         break;
      default:
         newClass = [GrowlGeneralViewController class];
         NSLog(@"Attempt to view unknown tab, loading general");
         break;
   }
   
   NSString *nibName = [newClass nibName];
   
   if(!prefViewControllers)
      prefViewControllers = [[NSMutableDictionary alloc] init];
   
   GrowlPrefsViewController *oldController = currentViewController;
   GrowlPrefsViewController *nextController = [prefViewControllers valueForKey:nibName];
   if(nextController && nextController == oldController)
      return;
   
   if(!nextController){
      nextController = [[newClass alloc] initWithNibName:nibName
                                                  bundle:nil 
                                             forPrefPane:self];
      [prefViewControllers setValue:nextController forKey:nibName];
   }
   
   NSWindow *aWindow = self.window;
   NSRect newFrameRect = [aWindow frameRectForContentRect:nextController.view.frame];
   NSRect oldFrameRect = aWindow.frame;
   
   NSSize newSize = newFrameRect.size;
   NSSize oldSize = oldFrameRect.size;
   NSSize minSize = self.window.minSize;

   if(minSize.width > newSize.width)
      newSize.width = minSize.width;
   
   NSRect frame = aWindow.frame;
   frame.size = newSize;
   frame.origin.y -= (newSize.height - oldSize.height);
    frame.origin.x -= (newSize.width - oldSize.width)/2.0f;
   [oldController viewWillUnload];
   aWindow.contentView = [[NSView alloc] initWithFrame:NSZeroRect];
   [oldController viewDidUnload];
    
   self.currentViewController = nextController;
   [aWindow setFrame:frame display:YES animate:YES];
   
   [nextController viewWillLoad];
   aWindow.contentView = nextController.view;
   [aWindow makeFirstResponder:nextController.view];
   [nextController viewDidLoad];
}

-(IBAction)selectedTabChanged:(id)sender
{
    preferencesController.selectedPreferenceTab = [sender itemIdentifier].integerValue;
}

-(BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    return YES;
}

-(NSArray*)toolbarSelectableItemIdentifiers:(NSToolbar*)aToolbar
{
    return @[@"0", @"1", @"2", @"3", @"4", @"5", @"6"];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
   return @[NSToolbarFlexibleSpaceItemIdentifier, @"0", @"1", @"2", @"3", @"4", @"5", @"6"];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)aToolbar 
{
   return @[NSToolbarFlexibleSpaceItemIdentifier, @"0", @"1", @"2", @"3", @"4", @"5", @"6", NSToolbarFlexibleSpaceItemIdentifier];
}

-(void)releaseTab:(GrowlPrefsViewController *)tab
{
   if(tab == currentViewController) {
      NSLog(@"Should not let current view controller go for performance on prefs reload");
      return;
   }
   [prefViewControllers removeObjectForKey:[[tab class] nibName]];
}

@end
