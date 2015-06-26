//
//  AppDelegate.h
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/2/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GrowlOnSwitch, HWGrowlPluginController;

typedef enum : NSInteger {
	kShowIconInMenu = 0,
	kShowIconInDock = 1,
	kShowIconInBoth = 2,
	kDontShowIcon = 3
} HWGrowlIconState;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSToolbarDelegate, NSTableViewDelegate, NSWindowDelegate> {
	NSWindow *__weak _window;
	NSStatusItem *statusItem;
	IBOutlet NSMenu *statusMenu;
	
	IBOutlet NSPopUpButton *__weak iconPopUp;
	IBOutlet GrowlOnSwitch *onLoginSwitch;
	
	HWGrowlIconState oldIconValue;
	BOOL oldOnLoginValue;
	
	HWGrowlPluginController *pluginController;
		
	NSToolbar *__weak toolbar;
	NSToolbarItem *__weak generalItem;
	NSToolbarItem *__weak modulesItem;
	NSTabView *__weak tabView;
	NSTableView *__weak tableView;
	NSTableColumn *__weak moduleColumn;
	NSView *__weak containerView;
	NSTextField *__weak noPrefsLabel;
	NSView *placeholderView;
	NSView *__weak currentView;
	
	NSString *showDevices;
	NSString *quitTitle;
	NSString *preferencesTitle;
	NSString *openPreferencesTitle;
	NSString *iconTitle;
	NSString *startAtLoginTitle;
	NSString *noPluginPrefsTitle;
	NSString *moduleLabel;
	
	NSString *iconInMenu;
	NSString *iconInDock;
	NSString *iconInBoth;
	NSString *noIcon;
   
   ProcessSerialNumber previousPSN;
}

@property (nonatomic, strong) IBOutlet NSString *showDevices;
@property (nonatomic, strong) IBOutlet NSString *quitTitle;
@property (nonatomic, strong) IBOutlet NSString *preferencesTitle;
@property (nonatomic, strong) IBOutlet NSString *openPreferencesTitle;
@property (nonatomic, strong) IBOutlet NSString *iconTitle;
@property (nonatomic, strong) IBOutlet NSString *startAtLoginTitle;
@property (nonatomic, strong) IBOutlet NSString *noPluginPrefsTitle;
@property (nonatomic, strong) IBOutlet NSString *moduleLabel;

@property (nonatomic, strong) NSString *iconInMenu;
@property (nonatomic, strong) NSString *iconInDock;
@property (nonatomic, strong) NSString *iconInBoth;
@property (nonatomic, strong) NSString *noIcon;

@property (weak) IBOutlet NSWindow *window;
@property (nonatomic, weak) IBOutlet NSPopUpButton *iconPopUp;
@property (nonatomic, strong) HWGrowlPluginController *pluginController;

@property (nonatomic, weak) IBOutlet NSToolbar *toolbar;
@property (nonatomic, weak) IBOutlet NSToolbarItem *generalItem;
@property (nonatomic, weak) IBOutlet NSToolbarItem *modulesItem;
@property (nonatomic, weak) IBOutlet NSTabView *tabView;
@property (nonatomic, weak) IBOutlet NSTableColumn *moduleColumn;
@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) IBOutlet NSView *containerView;
@property (nonatomic, weak) IBOutlet NSTextField *noPrefsLabel;
@property (nonatomic, strong) IBOutlet NSView *placeholderView;
@property (nonatomic, weak) IBOutlet NSView *currentView;

@end
