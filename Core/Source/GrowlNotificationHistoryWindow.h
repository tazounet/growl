//
//  GrowlNotificationHistoryWindow.h
//  Growl
//
//  Created by Daniel Siemer on 9/2/10.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlAbstractDatabase.h"
#import "GroupedArrayController.h"

@class GrowlNotificationDatabase, GroupedArrayController;

@interface GrowlNotificationHistoryWindow : NSWindowController <NSTableViewDelegate, NSTableViewDataSource, GroupedArrayControllerDelegate> {
   IBOutlet NSTableView *__weak historyTable;
   IBOutlet NSTextField *__weak countLabel;
   IBOutlet NSTableColumn *__weak notificationColumn;
   GrowlNotificationDatabase *__weak _notificationDatabase;

   GroupedArrayController *groupController;

   NSMutableArray *rowHeights;
}
-(id)initWithNotificationDatabase:(GrowlNotificationDatabase *)notificationDatabase;

@property (nonatomic, weak) IBOutlet NSTableView *historyTable;
@property (nonatomic, weak) IBOutlet NSTextField *countLabel;
@property (nonatomic, weak) IBOutlet NSTableColumn *notificationColumn;
@property (nonatomic, weak, readwrite)  GrowlNotificationDatabase* notificationDatabase;
@property (nonatomic, strong) NSString *windowTitle;
@property (nonatomic, strong) GroupedArrayController *groupController;

-(void)updateCount;
-(void)resetArray;
-(IBAction)deleteNotifications:(id)sender;
-(IBAction)deleteAppNotifications:(id)sender;
-(CGFloat)heightForDescription:(NSString*)description forWidth:(CGFloat)width;

@end
