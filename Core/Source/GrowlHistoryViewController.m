//
//  GrowlHistoryViewController.m
//  Growl
//
//  Created by Daniel Siemer on 11/10/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlHistoryViewController.h"
#import "GrowlNotificationDatabase.h"
#import "GrowlOnSwitch.h"

@implementation GrowlHistoryViewController

@synthesize notificationDatabase=_notificationDatabase;
@synthesize historyOnOffSwitch;
@synthesize historyArrayController;
@synthesize historyTable;
@synthesize trimByCountCheck;
@synthesize trimByDateCheck;
@synthesize historySearchField;

@synthesize enableHistoryLabel;
@synthesize keepAmountLabel;
@synthesize keepDaysLabel;
@synthesize applicationColumnLabel;
@synthesize titleColumnLabel;
@synthesize timeColumnLabel;
@synthesize clearAllHistoryButtonTitle;


-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil forPrefPane:(GrowlPreferencePane *)aPrefPane
{
    if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil forPrefPane:aPrefPane])){
        self.notificationDatabase = [GrowlNotificationDatabase sharedInstance];   
      self.enableHistoryLabel = NSLocalizedString(@"Enable History:", @"Label for the on/off switfh for enabling history");
      self.keepAmountLabel = NSLocalizedString(@"Keep Amount", @"Label for checkbox for keeping up to an amount of notifications");
      self.keepDaysLabel = NSLocalizedString(@"Keep Days", @"Label for checkbox for keeping up to a certain number of days worth of notifications");
      self.applicationColumnLabel = NSLocalizedString(@"Application", @"Column title for the applications column in the history table");
      self.titleColumnLabel = NSLocalizedString(@"Title", @"Column title for the title column in the history table");
      self.timeColumnLabel = NSLocalizedString(@"Time", @"Column title for the time column in the history table");
      self.clearAllHistoryButtonTitle = NSLocalizedString(@"Clear All History", @"Clear all history button title");
      [historySearchField.cell setPlaceholderString:NSLocalizedString(@"Search", @"Placeholder text in search field")];
   }
   return self;
}

-(void) awakeFromNib {
   [historySearchField.cell setPlaceholderString:NSLocalizedString(@"Search", @"History search field placeholder")];
   historyTable.autosaveName = @"GrowlPrefsHistoryTable";
   [historyTable setAutosaveTableColumns:YES];
   
   [historyOnOffSwitch addObserver:self 
                        forKeyPath:@"state" 
                           options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld 
                           context:nil];
    
    //set our default sort descriptor so that we're looking at new stuff at the top by default
    NSSortDescriptor *ascendingTime = [NSSortDescriptor sortDescriptorWithKey:@"Time" ascending:NO];
    historyArrayController.sortDescriptors = @[ascendingTime];
   
   [[NSNotificationCenter defaultCenter] addObserver:self 
                                            selector:@selector(growlDatabaseDidUpdate:) 
                                                name:@"GrowlDatabaseUpdated" 
                                              object:self.notificationDatabase];
   
   [self reloadPrefs:nil];
}

+ (NSString*)nibName {
   return @"HistoryPrefs";
}

- (void)dealloc
{
   [historyOnOffSwitch removeObserver:self forKeyPath:@"state"];
   
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
   if(object == historyOnOffSwitch && [keyPath isEqualToString:@"state"])
      (self.preferencesController).growlHistoryLogEnabled = historyOnOffSwitch.state;
}

- (void) reloadPrefs:(NSNotification *)notification {
	// ignore notifications which are sent by ourselves
	@autoreleasepool {
        id object = notification.object;
        if(!object || [object isEqualToString:GrowlHistoryLogEnabled]){
			historyOnOffSwitch.state = (self.preferencesController).isGrowlHistoryLogEnabled;
        }
    }
}

#pragma mark HistoryTab

-(void)growlDatabaseDidUpdate:(NSNotification*)notification
{
    [historyArrayController fetch:self];
}

-(IBAction)validateHistoryTrimSetting:(id)sender
{
    if(trimByDateCheck.state == NSOffState && trimByCountCheck.state == NSOffState)
    {
        NSLog(@"User tried turning off both automatic trim options");
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString(@"Turning off both automatic trim functions is not allowed.", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Ok", nil)];
        [alert setInformativeText:NSLocalizedString(@"To prevent the history database from growing indefinitely, at least one type of automatic trim must be active", nil)];

        [alert runModal];
        if ([sender isEqualTo:trimByDateCheck]) {
            [self.preferencesController setGrowlHistoryTrimByDate:YES];
        }
        
        if([sender isEqualTo:trimByCountCheck]){
            [self.preferencesController setGrowlHistoryTrimByCount:YES];
        }
    }
}

- (IBAction) deleteSelectedHistoryItems:(id)sender
{
   [[GrowlNotificationDatabase sharedInstance] deleteSelectedObjects:historyArrayController.selectedObjects];
   [historyArrayController rearrangeObjects];
}

- (IBAction) clearAllHistory:(id)sender
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(@"Warning! About to delete ALL history", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Ok", nil)];
    [alert setInformativeText:NSLocalizedString(@"This action cannot be undone, please confirm that you want to delete the entire notification history", nil)];

    [alert beginSheetModalForWindow:[sender window] completionHandler:^(NSModalResponse returnCode) {
        [self clearAllHistoryAlert:returnCode];
    }];
}

- (IBAction) clearAllHistoryAlert:(NSModalResponse)returnCode
{
    switch (returnCode) {
        case NSAlertFirstButtonReturn:
            NSLog(@"Doing nothing");
            break;
        case NSAlertSecondButtonReturn:
            [[GrowlNotificationDatabase sharedInstance] deleteAllHistory];
            break;
    }
}

- (void)openSettings:(BOOL)notification {
   id obj = historyArrayController.arrangedObjects[historyTable.clickedRow];
   NSString *appName =  [obj valueForKey:@"ApplicationName"];
   NSString *hostName = [obj valueForKeyPath:[NSString stringWithFormat:@"GrowlDictionary.%@", GROWL_NOTIFICATION_GNTP_SENT_BY]];
   NSString *noteName = notification ? [obj valueForKey:@"Name"] : nil;
   //NSLog(@"Selected (<application> - <host> : <note>) %@ - %@ : %@", appName, hostName, noteName);
   NSCharacterSet *set = [NSCharacterSet URLPathAllowedCharacterSet];
   NSString *urlString = [NSString stringWithFormat:@"growl://preferences/applications/%@/%@/%@", appName, (hostName ? hostName : @""), (noteName ? noteName : @"")];
   urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:set];
   //NSLog(@"url: %@", urlString);
   [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];

}

- (IBAction)openAppSettings:(id)sender {
   [self openSettings:NO];
}

- (IBAction)openNoteSettings:(id)sender {
   [self openSettings:YES];
}

@end
