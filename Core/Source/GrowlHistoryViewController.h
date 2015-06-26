//
//  GrowlHistoryViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/10/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"

@class GrowlNotificationDatabase, GrowlOnSwitch;

@interface GrowlHistoryViewController : GrowlPrefsViewController {
    GrowlNotificationDatabase *__weak _notificationDatabase;
}

@property (nonatomic, weak) GrowlNotificationDatabase *notificationDatabase;
@property (nonatomic, weak) IBOutlet GrowlOnSwitch *historyOnOffSwitch;
@property (nonatomic, weak) IBOutlet NSArrayController *historyArrayController;
@property (nonatomic, weak) IBOutlet NSTableView *historyTable;
@property (nonatomic, weak) IBOutlet NSButton *trimByCountCheck;
@property (nonatomic, weak) IBOutlet NSButton *trimByDateCheck;
@property (nonatomic, weak) IBOutlet NSSearchField *historySearchField;

@property (nonatomic, strong) NSString *enableHistoryLabel;
@property (nonatomic, strong) NSString *keepAmountLabel;
@property (nonatomic, strong) NSString *keepDaysLabel;
@property (nonatomic, strong) NSString *applicationColumnLabel;
@property (nonatomic, strong) NSString *titleColumnLabel;
@property (nonatomic, strong) NSString *timeColumnLabel;
@property (nonatomic, strong) NSString *clearAllHistoryButtonTitle;

- (void) reloadPrefs:(NSNotification*)notification;

- (IBAction) validateHistoryTrimSetting:(id)sender;
- (IBAction) deleteSelectedHistoryItems:(id)sender;
- (IBAction) clearAllHistory:(id)sender;
- (IBAction) openAppSettings:(id)sender;
- (IBAction) openNoteSettings:(id)sender;

@end
