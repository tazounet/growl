//
//  AppDelegate.m
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/2/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "AppDelegate.h"
#import "GrowlOnSwitch.h"
#import "HWGrowlPluginController.h"
#import "ACImageAndTextCell.h"
#import <ServiceManagement/ServiceManagement.h>

#define ShowDevicesTitle     NSLocalizedString(@"Show Connected Devices at Launch", nil)
#define QuitTitle            NSLocalizedString(@"Quit HardwareGrowler", nil)
#define PreferencesTitle     NSLocalizedString(@"Preferences", nil)
#define OpenPreferencesTitle NSLocalizedString(@"Open HardwareGrowler Preferences...", nil)
#define IconTitle            NSLocalizedString(@"Icon:", nil)
#define StartAtLoginTitle    NSLocalizedString(@"Start HardwareGrowler at Login:", nil)
#define NoPluginPrefsTitle   NSLocalizedString(@"There are no preferences available for this monitor.", @"")
#define ModuleLabel          NSLocalizedString(@"Modules", @"")

@interface AppDelegate ()

@property (nonatomic, assign) ProcessSerialNumber previousPSN;

@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize iconPopUp;
@synthesize pluginController;

@synthesize showDevices;
@synthesize quitTitle;
@synthesize preferencesTitle;
@synthesize openPreferencesTitle;
@synthesize iconTitle;
@synthesize startAtLoginTitle;
@synthesize noPluginPrefsTitle;
@synthesize moduleLabel;

@synthesize iconInMenu;
@synthesize iconInDock;
@synthesize iconInBoth;
@synthesize noIcon;

@synthesize toolbar;
@synthesize generalItem;
@synthesize modulesItem;
@synthesize tabView;
@synthesize tableView;
@synthesize moduleColumn;
@synthesize containerView;
@synthesize noPrefsLabel;
@synthesize placeholderView;
@synthesize currentView;


+(void)initialize
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{@"OnLogin": @NO,
																				@"ShowExisting": @YES,
																				@"GroupNetwork": @NO,
																				@"Visibility": @0}];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[super initialize];
}


- (void) awakeFromNib {
	self.iconInMenu = NSLocalizedString(@"Show icon in the menubar", @"default option for where the icon should be seen");
	self.iconInDock = NSLocalizedString(@"Show icon in the dock", @"display the icon only in the dock");
	self.iconInBoth = NSLocalizedString(@"Show icon in both", @"display the icon in both the menubar and the dock");
	self.noIcon = NSLocalizedString(@"No icon visible", @"display no icon at all");
	
	[generalItem setLabel:NSLocalizedString(@"General", @"")];
	[modulesItem setLabel:NSLocalizedString(@"Modules", @"")];
	
	NSNumber *visibility = [[NSUserDefaults standardUserDefaults] objectForKey:@"Visibility"];
	if(visibility == nil || visibility.integerValue == kShowIconInDock || visibility.integerValue == kShowIconInBoth){
		[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
	}
	
	if(visibility == nil || visibility.integerValue == kShowIconInMenu || visibility.integerValue == kShowIconInBoth){
		[self initMenu];
	}
	
	onLoginSwitch.state = [[NSUserDefaultsController sharedUserDefaultsController].defaults boolForKey:@"OnLogin"];
   [onLoginSwitch addObserver:self 
						 forKeyPath:@"state" 
							 options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
							 context:nil];
	
	self.pluginController = [[HWGrowlPluginController alloc] init];
	
	
	NSShadow *shadow = [[NSShadow alloc] init];
	shadow.shadowColor = [NSColor colorWithDeviceWhite:1.0 alpha:.75];
	shadow.shadowOffset = CGSizeMake(0.0, -1.0);
	
	NSDictionary *attrDict = @{NSFontAttributeName: [NSFont systemFontOfSize:13.0f],
									  NSForegroundColorAttributeName: [NSColor colorWithDeviceWhite:0.5f alpha:1.0f],
									  NSShadowAttributeName: shadow};
	NSMutableAttributedString *noPrefsAttributed = [[NSMutableAttributedString alloc] initWithString:NoPluginPrefsTitle 
																													  attributes:attrDict];
	[noPrefsAttributed setAlignment:NSTextAlignmentCenter range:NSMakeRange(0, noPrefsAttributed.length)];

	
	noPrefsLabel.attributedStringValue = noPrefsAttributed;
	
	ACImageAndTextCell *imageTextCell = [[ACImageAndTextCell alloc] init];
   moduleColumn.dataCell = imageTextCell;
}

- (IBAction)showPreferences:(id)sender
{
    // Tweak for menu bar
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSRunningApplication * app in [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.dock"]) {
            [app activateWithOptions:NSApplicationActivateIgnoringOtherApps];
            break;
        }
        [self performSelector:@selector(showPreferencesStep2) withObject:nil afterDelay:0.1];
    });
}

- (void)showPreferencesStep2
{
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    TransformProcessType(&psn, kProcessTransformToForegroundApplication);
    
    [self performSelector:@selector(showPreferencesStep3) withObject:nil afterDelay:0.1];
}

- (void)showPreferencesStep3
{
    [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];
    if(!(self.window).visible) {
        [self.window center];
        [self.window setFrameAutosaveName:@"HWGrowlerPrefsWindowFrame"];
        [self.window setFrameUsingName:@"HWGrowlerPrefsWindowFrame" force:YES];
    }
    
    [self.window makeKeyAndOrderFront:nil];
}

- (void)windowWillClose:(NSNotification *)notification {
    NSNumber *value = [[NSUserDefaultsController sharedUserDefaultsController].defaults valueForKey:@"Visibility"];
    HWGrowlIconState visibility = value.integerValue;
    if(visibility == kDontShowIcon || visibility == kShowIconInMenu){
        dispatch_async(dispatch_get_main_queue(), ^{
            ProcessSerialNumber psn = { 0, kCurrentProcess };
            TransformProcessType(&psn, kProcessTransformToUIElementApplication);
        });
    }
}

- (void) initMenu{
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	statusItem.menu = statusMenu;
	
	NSString* icon_path = [[NSBundle mainBundle] pathForResource:@"menubarIcon_Normal" ofType:@"png"];
	NSImage *icon = [[NSImage alloc] initWithContentsOfFile:icon_path];
    [icon setTemplate:YES];
    
	statusItem.image = icon;

	[statusItem setHighlightMode:YES];
}

- (void) initTitles{
	self.showDevices = ShowDevicesTitle;
	self.quitTitle = QuitTitle;
	self.preferencesTitle = PreferencesTitle;
	self.openPreferencesTitle = OpenPreferencesTitle;
	self.iconTitle = IconTitle;
	self.startAtLoginTitle = StartAtLoginTitle;
	self.noPluginPrefsTitle = NoPluginPrefsTitle;
	self.moduleLabel = ModuleLabel;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{    
	[self.toolbar setVisible:YES];
	if(self.toolbar.items.count == 0){
		[self.toolbar insertItemWithItemIdentifier:@"General" atIndex:0];
		[self.toolbar insertItemWithItemIdentifier:@"Modules" atIndex:1];
	}
	[self selectTabIndex:0];
	[self expiryCheck];
	[self initTitles];
		
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self 
																				 forKeyPath:@"values.Visibility" 
																					 options:NSKeyValueObservingOptionNew 
																					 context:nil];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self 
																				 forKeyPath:@"values.OnLogin" 
																					 options:NSKeyValueObservingOptionNew 
																					 context:nil];
	oldIconValue = [[NSUserDefaultsController sharedUserDefaultsController].defaults integerForKey:@"Visibility"];
	oldOnLoginValue = [[NSUserDefaultsController sharedUserDefaultsController].defaults boolForKey:@"OnLogin"];
}

- (BOOL) applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	[self showPreferences:self];
	return YES;
}

- (void)observeValueForKeyPath:(NSString*)keyPath 
							 ofObject:(id)object 
								change:(NSDictionary*)change 
							  context:(void*)context
{
	NSUserDefaultsController *defaultController = [NSUserDefaultsController sharedUserDefaultsController];
	if([keyPath isEqualToString:@"values.Visibility"])
	{
		NSNumber *value = [defaultController.defaults valueForKey:@"Visibility"];
		HWGrowlIconState index   = value.integerValue;
		switch (index) {
			case kDontShowIcon:
				if(![defaultController.defaults boolForKey:@"SuppressNoIconWarn"])
				{
					[NSApp activateIgnoringOtherApps:YES];

                    NSAlert *alert = [[NSAlert alloc] init];
                    [alert setMessageText:NSLocalizedString(@"Warning! Enabling this option will cause HardwareGrowler to run in the background", nil)];
                    [alert addButtonWithTitle:NSLocalizedString(@"Ok", nil)];
                    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
                    [alert setInformativeText:NSLocalizedString(@"Enabling this option will cause HardwareGrowler to run without showing a dock icon or a menu item.\n\nTo access preferences, tap HardwareGrowler in Launchpad, or open HardwareGrowler in Finder.", nil)];

                    alert.alertStyle = NSAlertStyleWarning;
                    [alert setShowsSuppressionButton:YES];
                    
                    if([alert runModal] == NSAlertFirstButtonReturn)
					{
						if(alert.suppressionButton.state == NSOnState){
							[defaultController.defaults setBool:YES forKey:@"SuppressNoIconWarn"];
						}
						[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
						statusItem = nil;
					}
					else
					{
						[defaultController.defaults setInteger:oldIconValue forKey:@"Visibility"];
						[defaultController.defaults synchronize];
						[iconPopUp selectItemAtIndex:oldIconValue];
					}
				}else{
					[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
					statusItem = nil;
				}
				break;
			case kShowIconInBoth:
				[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
				if(!statusItem)
					[self initMenu];
				break;
			case kShowIconInDock:
				[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
				[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
				statusItem = nil;
				break;
			case kShowIconInMenu:
			default:
				if(!statusItem)
					[self initMenu];
				break;
		}
		oldIconValue = index;
	}
	else if ([keyPath isEqualToString:@"values.OnLogin"])
	{
		BOOL state = [defaultController.defaults boolForKey:@"OnLogin"];
		if(state && (oldOnLoginValue != state))
		{
			if(![defaultController.defaults boolForKey:@"SuppressStartAtLogin"])
			{
				[NSApp activateIgnoringOtherApps:YES];

                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:NSLocalizedString(@"Alert! Enabling this option will add HardwareGrowler to your login items", nil)];
                [alert addButtonWithTitle:NSLocalizedString(@"Ok", nil)];
                [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
                [alert setInformativeText:NSLocalizedString(@"Allowing this will let HardwareGrowler launch everytime you login, so that it is available for applications which use it at all times", nil)];

                alert.alertStyle = NSAlertStyleWarning;
                [alert setShowsSuppressionButton:YES];

				if([alert runModal] == NSAlertFirstButtonReturn)
				{
					if(alert.suppressionButton.state == NSOnState){
						[defaultController.defaults setBool:YES forKey:@"SuppressStartAtLogin"];
					}
					[self setStartAtLogin:YES];
				}
				else
				{
					[self setStartAtLogin:NO];
					[defaultController.defaults setBool:oldOnLoginValue forKey:@"OnLogin"];
					[defaultController.defaults synchronize];
					onLoginSwitch.state = oldOnLoginValue;
				}
			}else{
				[self setStartAtLogin:YES];
			}
		}
		else{
			[self setStartAtLogin:NO];
		}
		oldOnLoginValue = state;
	}
	else if(object == onLoginSwitch && [keyPath isEqualToString:@"state"])
	{
		[defaultController.values setValue:@(onLoginSwitch.state) forKey:@"OnLogin"];
		[defaultController save:nil];
	}
}

- (void) setStartAtLogin:(BOOL)enabled {
   if(!SMLoginItemSetEnabled(CFSTR("com.growl.HardwareGrowlerLauncher"), enabled)){
      NSLog(@"Failure Setting HardwareGrowlLauncher to %@start at login", enabled ? @"" : @"not ");
   }
}

#pragma mark Module Table

-(IBAction)moduleCheckbox:(id)sender {
	NSInteger selection = tableView.clickedRow;
	if(selection >= 0 && (NSUInteger)selection < pluginController.plugins.count){
		NSMutableDictionary *pluginDict = pluginController.plugins[selection];
		id<HWGrowlPluginProtocol> plugin = pluginDict[@"plugin"];
		NSString *identifier = [NSBundle bundleForClass:[plugin class]].bundleIdentifier;
		NSNumber *disabled = pluginDict[@"disabled"];
		
		if(disabled.boolValue){
			if([plugin respondsToSelector:@selector(stopObserving)])
				[plugin stopObserving];
		}else{
			if([plugin respondsToSelector:@selector(startObserving)])
				[plugin startObserving];
		}
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSMutableDictionary *disabledDict = [[defaults objectForKey:@"DisabledPlugins"] mutableCopy];
		if(!disabledDict)
			disabledDict = [NSMutableDictionary dictionary];
		disabledDict[identifier] = disabled;
		[defaults setObject:disabledDict forKey:@"DisabledPlugins"];
		[defaults synchronize];
	}
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification {
	NSInteger selection = tableView.selectedRow;
	NSView *newView = nil;
	if(selection >= 0 && (NSUInteger)selection < pluginController.plugins.count){
		id<HWGrowlPluginProtocol> plugin = pluginController.plugins[selection][@"plugin"];
		if(plugin.preferencePane){
			newView = plugin.preferencePane;
		}else{
			newView = placeholderView;
		}
	}else
		newView = placeholderView;
	[newView setFrameSize:containerView.frame.size];
	if(currentView.superview)
		[currentView removeFromSuperview];
	[containerView addSubview:newView];
	self.currentView = newView;
	[_window recalculateKeyViewLoop];
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if (aTableColumn == moduleColumn) {
		NSCell *cell = [aTableColumn dataCellForRow:rowIndex];
		id<HWGrowlPluginProtocol> plugin = pluginController.plugins[rowIndex][@"plugin"];
		if(plugin.preferenceIcon)
			cell.image = plugin.preferenceIcon;
		else{
			static NSImage *placeholder = nil;
			static dispatch_once_t onceToken;
			dispatch_once(&onceToken, ^{
				placeholder = [NSImage imageNamed:@"HWGPrefsDefault"];
			});
			cell.image = placeholder;
		}
   }
	return nil;
}

#pragma mark Toolbar

-(void)selectTabIndex:(NSInteger)tab {
	if(tab < 0 || tab > 1)
		tab = 0;
	toolbar.selectedItemIdentifier = [NSString stringWithFormat:@"%ld", tab];
	[tabView selectTabViewItemAtIndex:tab];
}

-(IBAction)selectTab:(id)sender {
	[self selectTabIndex:[sender tag]];
}

-(BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
	return YES;
}

-(NSArray*)toolbarSelectableItemIdentifiers:(NSToolbar*)aToolbar
{
	return @[@"0", @"1"];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
   return @[@"0", @"1"];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)aToolbar 
{
   return @[@"0", @"1"];
}

#ifdef BETA
#define DAYSTOEXPIRY 21
- (NSCalendarDate *)dateWithString:(NSString *)str {
	str = [str stringByReplacingOccurrencesOfString:@"  " withString:@" "];
	NSArray *dateParts = [str componentsSeparatedByString:@" "];
	int month = 1;
	NSString *monthString = [dateParts objectAtIndex:0];
	if ([monthString isEqualToString:@"Feb"]) {
		month = 2;
	} else if ([monthString isEqualToString:@"Mar"]) {
		month = 3;
	} else if ([monthString isEqualToString:@"Apr"]) {
		month = 4;
	} else if ([monthString isEqualToString:@"May"]) {
		month = 5;
	} else if ([monthString isEqualToString:@"Jun"]) {
		month = 6;
	} else if ([monthString isEqualToString:@"Jul"]) {
		month = 7;
	} else if ([monthString isEqualToString:@"Aug"]) {
		month = 8;
	} else if ([monthString isEqualToString:@"Sep"]) {
		month = 9;
	} else if ([monthString isEqualToString:@"Oct"]) {
		month = 10;
	} else if ([monthString isEqualToString:@"Nov"]) {
		month = 11;
	} else if ([monthString isEqualToString:@"Dec"]) {
		month = 12;
	}
	
	NSString *dateString = [NSString stringWithFormat:@"%@-%d-%@ 00:00:00 +0000", [dateParts objectAtIndex:2], month, [dateParts objectAtIndex:1]];
	return [NSCalendarDate dateWithString:dateString];
}

- (BOOL)expired
{
	BOOL result = YES;
	
	NSCalendarDate* nowDate = [self dateWithString:[NSString stringWithUTF8String:__DATE__]];
	NSCalendarDate* expiryDate = [nowDate dateByAddingTimeInterval:(60*60*24* DAYSTOEXPIRY)];
	
	if ([expiryDate earlierDate:[NSDate date]] != expiryDate)
		result = NO;
	
	return result;
}

- (void)expiryCheck
{
	if([self expired])
	{
		[NSApp activateIgnoringOtherApps:YES];
		NSInteger alert = NSRunAlertPanel(@"This Beta Has Expired", [NSString stringWithFormat:@"Please download a new version to keep using %@.", [[NSProcessInfo processInfo] processName]], @"Quit", nil, nil);
		if (alert == NSOKButton) 
		{
			[NSApp terminate:self];
		}
	}
}
#else
- (void)expiryCheck{
}
#endif

@end
