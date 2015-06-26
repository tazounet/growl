//
//  GrowlApplicationsViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/9/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"
#import "GroupedArrayController.h"

@class GroupedArrayController, GrowlTicketDatabase, NotificationsArrayController, GrowlPositionPicker, GrowlOnSwitch;

@interface GrowlApplicationsViewController : GrowlPrefsViewController <NSTableViewDataSource, NSTableViewDelegate, GroupedArrayControllerDelegate>

@property (nonatomic, weak) IBOutlet NSTableView *growlApplications;
@property (nonatomic, weak) IBOutlet NSTableView *notificationsTable;
@property (nonatomic, weak) IBOutlet NSTableColumn *applicationsNameAndIconColumn;
@property (nonatomic, weak) IBOutlet GrowlTicketDatabase *ticketDatabase;
@property (nonatomic, strong) IBOutlet GroupedArrayController *ticketsArrayController;
@property (nonatomic, weak) IBOutlet NSArrayController *displayPluginsArrayController;
@property (nonatomic, weak) IBOutlet NSArrayController *actionConfigsArrayController;
@property (nonatomic, weak) IBOutlet NSArrayController *notificationsArrayController;
@property (nonatomic, weak) IBOutlet NSTabView *appSettingsTabView;
@property (nonatomic, weak) IBOutlet GrowlOnSwitch *appOnSwitch;
@property (nonatomic, weak) IBOutlet GrowlPositionPicker *appPositionPicker;
@property (nonatomic, weak) IBOutlet NSPopUpButton *displayMenuButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *notificationDisplayMenuButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *actionMenuButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *notificationActionMenuButton;
@property (nonatomic, weak) IBOutlet NSButton *enableLogging;
@property (nonatomic, weak) IBOutlet NSMatrix *positionPickerRadioButton;
@property (nonatomic, strong) NSIndexSet *selectedNotificationIndexes;

@property (nonatomic, weak) IBOutlet NSScrollView *applicationScrollView;
@property (nonatomic) BOOL canRemoveTicket;

@property (nonatomic, strong) NSString *getApplicationsTitle;
@property (nonatomic, strong) NSString *enableApplicationLabel;
@property (nonatomic, strong) NSString *enableLoggingLabel;
@property (nonatomic, strong) NSString *applicationDefaultStyleLabel;
@property (nonatomic, strong) NSString *applicationSettingsTabLabel;
@property (nonatomic, strong) NSString *notificationSettingsTabLabel;
@property (nonatomic, strong) NSString *defaultStartPositionLabel;
@property (nonatomic, strong) NSString *customStartPositionLabel;
@property (nonatomic, strong) NSString *noteDisplayStyleLabel;
@property (nonatomic, strong) NSString *stayOnScreenLabel;
@property (nonatomic, strong) NSString *priorityLabel;
@property (nonatomic, strong) NSString *stayOnScreenNever;
@property (nonatomic, strong) NSString *stayOnScreenAlways;
@property (nonatomic, strong) NSString *stayOnScreenAppDecides;
@property (nonatomic, strong) NSString *priorityLow;
@property (nonatomic, strong) NSString *priorityModerate;
@property (nonatomic, strong) NSString *priorityNormal;
@property (nonatomic, strong) NSString *priorityHigh;
@property (nonatomic, strong) NSString *priorityEmergency;

@property (nonatomic, strong) NSString *globalDefaultTitle;
@property (nonatomic, strong) NSString *appDefaultTitle;
@property (nonatomic, strong) NSString *noDefaultDisplayTitle;
@property (nonatomic, strong) NSString *noDefaultActionTitle;
@property (nonatomic, strong) NSString *actionsPopupTitle;
@property (nonatomic, strong) NSString *actionsPopupLabel;

- (BOOL) canRemoveTicket;
- (void) setCanRemoveTicket:(BOOL)flag;
- (IBAction)getApplications:(id)sender;
- (IBAction) deleteTicket:(id)sender;
- (void)selectApplication:(NSString*)appName hostName:(NSString*)hostName notificationName:(NSString*)noteNameOrNil;
- (NSIndexSet *) selectedNotificationIndexes;
- (void) setSelectedNotificationIndexes:(NSIndexSet *)newSelectedNotificationIndexes;

- (BOOL)tableView:(NSTableView*)tableView isGroupRow:(NSInteger)row;

@end
