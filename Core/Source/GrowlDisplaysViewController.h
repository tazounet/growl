//
//  GrowlDisplaysViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/10/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"
#import "GroupedArrayController.h"

@class GrowlPlugin, GrowlPluginController, GrowlTicketDatabase, GrowlTicketDatabasePlugin, GrowlPluginPreferencePane;

@interface GrowlDisplaysViewController : GrowlPrefsViewController <GroupedArrayControllerDelegate, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate>

@property (nonatomic, weak) GrowlPluginController *pluginController;
@property (nonatomic, weak) GrowlTicketDatabase *ticketDatabase;
@property (nonatomic, weak) IBOutlet NSTableView *displayPluginsTable;
@property (nonatomic, weak) IBOutlet NSView *displayPrefView;
@property (nonatomic, weak) IBOutlet NSView *displayDefaultPrefView;
@property (nonatomic, weak) IBOutlet NSTextField *displayAuthor;
@property (nonatomic, weak) IBOutlet NSTextField *displayVersion;
@property (nonatomic, weak) IBOutlet NSTextField *displayName;
@property (nonatomic, weak) IBOutlet NSButton *previewButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *defaultDisplayPopUp;
@property (nonatomic, weak) IBOutlet NSPopUpButton *defaultActionPopUp;
@property (nonatomic, strong) IBOutlet GroupedArrayController *pluginConfigGroupController;
@property (nonatomic, weak) IBOutlet NSArrayController *displayConfigsArrayController;
@property (nonatomic, weak) IBOutlet NSArrayController *actionConfigsArrayController;
@property (nonatomic, weak) IBOutlet NSArrayController *displayPluginsArrayController;

@property (nonatomic, weak) IBOutlet NSWindow *disabledDisplaysSheet;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextView *disabledDisplaysList;

@property (nonatomic, strong) GrowlPluginPreferencePane *pluginPrefPane;
@property (nonatomic, strong) NSMutableArray *loadedPrefPanes;

@property (nonatomic, strong) GrowlPlugin *currentPluginController;

@property (nonatomic, strong) NSString *defaultStyleLabel;
@property (nonatomic, strong) NSString *showDisabledButtonTitle;
@property (nonatomic, strong) NSString *getMoreStylesButtonTitle;
@property (nonatomic, strong) NSString *previewButtonTitle;
@property (nonatomic, strong) NSString *displayStylesColumnTitle;
@property (nonatomic, strong) NSString *noDefaultDisplayPluginLabel;

@property (nonatomic, strong) NSString *defaultActionsLabel;
@property (nonatomic, strong) NSString *addConfigButtonTitle;
@property (nonatomic, strong) NSString *defaultActionPopUpTitle;
@property (nonatomic, strong) NSString *addCompoundOption;
@property (nonatomic, strong) NSString *noActionsTitle;

@property (nonatomic, strong) NSString *disabledPluginSheetDescription;
@property (nonatomic, strong) NSString *disabledPluginSheetCloseButtonTitle;

@property (nonatomic) BOOL awokeFromNib;

- (void)selectDefaultPlugin:(NSString*)pluginID;
- (void)selectPlugin:(NSString*)pluginName;

- (IBAction) showDisabledDisplays:(id)sender;
- (IBAction) endDisabledDisplays:(id)sender;
- (IBAction)addConfiguration:(id)sender;
- (IBAction)deleteConfiguration:(id)sender;

- (IBAction) openGrowlWebSiteToStyles:(id)sender;
- (IBAction) showPreview:(id)sender;
- (void) loadViewForDisplay:(GrowlTicketDatabasePlugin*)displayName;

@end
