//
//  GrowlNotificationDatabase.m
//  Growl
//
//  Created by Daniel Siemer on 8/11/10.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import "GrowlNotificationDatabase.h"
#import "GrowlPreferencesController.h"
#import "GrowlDefines.h"
#import "GrowlHistoryNotification.h"
#import "GrowlPathUtilities.h"
#import "GrowlTicketDatabase.h"
#import "GrowlTicketDatabaseApplication.h"
#import "GrowlTicketDatabaseNotification.h"
#import "GrowlNotificationHistoryWindow.h"
#import "GrowlIdleStatusObserver.h"
#import <CoreData/CoreData.h>

@implementation GrowlNotificationDatabase

@synthesize historyWindow;
@synthesize notificationsWhileAway;

+(GrowlNotificationDatabase *)sharedInstance {
    static GrowlNotificationDatabase *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}


-(instancetype)init
{
   if((self = [super init]))
   {
      GrowlNotificationHistoryWindow *window = [[GrowlNotificationHistoryWindow alloc] initWithNotificationDatabase:self];
      historyWindow = window;
      [historyWindow resetArray];
      
      notificationsWhileAway = NO;
      if([GrowlPreferencesController sharedController].isRollupShown)
         [self showRollup];
   }
   return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [periodicSaveTimer invalidate];
     periodicSaveTimer = nil;
    [maintenanceTimer invalidate];
     maintenanceTimer = nil;
     lastImageCheck = nil;
}

-(NSString*)storePath
{
   return [[GrowlPathUtilities growlSupportDirectory] stringByAppendingPathComponent:@"notifications.history"];
}

-(NSString*)storeType
{
   return @"Notification History Database";
}

-(NSString*)modelName
{
   return @"GrowlNotificationHistory.mom";
}

-(void)launchFailed {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(@"Disabling History", @"alert when history database could not be moved aside")];
    [alert addButtonWithTitle:NSLocalizedString(@"Ok", nil)];
    [alert setInformativeText:NSLocalizedString(@"An uncorrectable error occured in creating or opening the History Database.\nWe are disabling History for the time being, however the rollup will continue to function.\nIf history is reenabled, nothing will be saved, and Growl will potentially use a lot of memory.", @"")];
    alert.alertStyle = NSAlertStyleCritical;
   [[GrowlPreferencesController sharedController] setGrowlHistoryLogEnabled:NO];
}

-(NSArray*)mostRecentNotifications:(unsigned int)amount
{
   if(amount == 0)
      amount = 1;
   
   NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Notification"];
      
   NSSortDescriptor *sortDescription = [[NSSortDescriptor alloc] initWithKey:@"Time" ascending:NO];
   NSArray *sortArray = @[sortDescription];
   request.sortDescriptors = sortArray;
   
   request.fetchLimit = amount;
   
    __block NSArray *awayHistory = nil;
    void (^recentBlock)(void) = ^{
        NSError *error = nil;
        awayHistory = [managedObjectContext executeFetchRequest:request error:&error];
        if(error)
            NSLog(@"Unresolved error %@, %@", error, error.userInfo);
    };
    if(![NSThread currentThread].isMainThread)
        [managedObjectContext performBlockAndWait:recentBlock];
    else
        recentBlock();
   return awayHistory;      
}

#pragma mark -

-(void)deleteSelectedObjects:(NSArray*)objects
{
    void (^deleteBlock)(void) = ^{
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Notification"];
        NSError *error = nil;
        
        NSArray *notes = [managedObjectContext executeFetchRequest:request error:&error];
        if(error)
        {
            NSLog(@"Unresolved error %@, %@", error, error.userInfo);
            return;
        }
        
        for(NSManagedObject *note in notes)
        {
            if([objects containsObject:note])
                [managedObjectContext deleteObject:note];
        }
    };
    if(![NSThread currentThread].isMainThread)
        [managedObjectContext performBlock:deleteBlock];
    else
        deleteBlock();
    [self saveDatabase:NO];
}

-(void)deleteAllHistory
{
    void (^deleteBlock)(void) = ^{
        NSError *error = nil;
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Notification"];
        
        NSArray *notes = [self.managedObjectContext executeFetchRequest:request error:&error];
        if(error)
        {
            NSLog(@"Unresolved error %@, %@", error, error.userInfo);
            return;
        }
        
        NSLog(@"Deleting Entire History");
        for(NSManagedObject *note in notes)
        {
            [self.managedObjectContext deleteObject:note];
        }
    };
    if(![NSThread currentThread].isMainThread)
        [managedObjectContext performBlock:deleteBlock];
    else
        deleteBlock();
    [self saveDatabase:NO];
}

#pragma mark -
#pragma mark Notification History Maintenance
/* StoreMaintenance cleans out old messages on a timer, either x max, y days old,
 * or whichever comes first depending on user prefrences.  Called only every half hour? need to decide that
 */
-(void)storeMaintenance:(NSTimer*)theTimer
{
   GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
   
   if(!preferences.isGrowlHistoryTrimByDate && !preferences.isGrowlHistoryTrimByCount)
   {
      NSLog(@"Setting trimByDate since both have been turned off outside of the UI");
      [preferences setGrowlHistoryTrimByDate:YES];
   }
   
   if(preferences.isGrowlHistoryTrimByDate)
   {
      [self trimByDate];
   }
   
   if(preferences.isGrowlHistoryTrimByCount)
   {
      [self trimByCount];
   }
   
   if(!lastImageCheck || [[NSDate date] timeIntervalSinceDate:lastImageCheck] > 3600 * 24)
   {
      [self imageCacheMaintenance];
      lastImageCheck = [NSDate date];
   }
   [self saveDatabase:NO];
}

- (void)periodicSave:(NSTimer*)timer
{
    [self saveDatabase:NO];    
}

-(void)trimByDate
{
    [managedObjectContext performBlock:^(void) {
        NSError *error = nil;
        
        GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];   
        
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Notification"];
        
        NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"Time" ascending:NO];
        request.sortDescriptors = @[dateSort];
        
        NSInteger trimDays = -preferences.growlHistoryDayLimit;
        
        NSCalendar *calender = [NSCalendar autoupdatingCurrentCalendar];
        NSDateComponents *dateComponent = [[NSDateComponents alloc]init];
        dateComponent.day = trimDays;
        NSDate *trimDate = [calender dateByAddingComponents:dateComponent toDate:[NSDate dateWithTimeIntervalSinceNow:0] options:NSCalendarWrapComponents];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Time <= %@", trimDate];
        request.predicate = predicate;
        
        NSArray *notes = [managedObjectContext executeFetchRequest:request error:&error];
        if(error)
        {
            NSLog(@"Unresolved error %@, %@", error, error.userInfo);
            return;
        }
        
        for(NSManagedObject *note in notes)
        {
            [managedObjectContext deleteObject:note];
        }
    }];
}

-(void)trimByCount
{
    [managedObjectContext performBlock:^(void) {
        GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
        
        NSError *error = nil;
        NSFetchRequest *countRequest = [[NSFetchRequest alloc] initWithEntityName:@"Notification"];
        
        NSUInteger totalCount = [managedObjectContext countForFetchRequest:countRequest error:&error];
        if(error)
        {
            NSLog(@"Unresolved error %@, %@", error, error.userInfo);
            return;
        }
        NSUInteger countLimit = preferences.growlHistoryCountLimit;
        if (totalCount <= countLimit)
        {
            return;
        }
        
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Notification"];
        request.fetchLimit = totalCount - countLimit;
        
        NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"Time" ascending:YES];
        request.sortDescriptors = @[dateSort];
        
        NSArray *notes = [managedObjectContext executeFetchRequest:request error:&error];
        
        if(error)
        {
            NSLog(@"Unresolved error %@, %@", error, error.userInfo);
            return;
        }
        for(NSManagedObject *note in notes)
        {
            [managedObjectContext deleteObject:note];
        }
    }];
}

-(void)imageCacheMaintenance
{
    [managedObjectContext performBlock:^(void) {
        NSError *error = nil;
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Image"];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ANY Notifications == nil"];
        request.predicate = predicate;
        
        NSArray *images = [managedObjectContext executeFetchRequest:request error:&error];
        if(error)
        {
            NSLog(@"Unresolved error %@, %@", error, error.userInfo);
            return;
        }
        
        if(images.count == 0)
        {
            return;
        }
        
        for(NSManagedObject *image in images)
        {
            [managedObjectContext deleteObject:image];
        }
    }];
}

-(void)userReturnedAndClosedList
{
    notificationsWhileAway = NO;
    
    [managedObjectContext performBlock:^(void) {
        NSError *error = nil;
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Notification"];
        NSNumber *boolYES = @YES;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(deleteUponReturn == %@) OR (showInRollup == %@)", boolYES, boolYES];
        request.predicate = predicate;
        
        NSArray *notes = [managedObjectContext executeFetchRequest:request error:&error];
        if(error)
        {
            NSLog(@"Unresolved error %@, %@", error, error.userInfo);
            return;
        }
        
        for(GrowlHistoryNotification *note in notes)
        {
            if(note.deleteUponReturn.boolValue)
                [managedObjectContext deleteObject:note];
            else
                note.showInRollup = @NO;
        }        
    }];
    [self saveDatabase:NO];
}

-(void)setupMaintenanceTimers
{   
    if(maintenanceTimer)
    {
        NSLog(@"Timer appears to already be setup, setupMaintenanceTimers should only be called once");
        return;
    }
    NSLog(@"Setup timer, this should only happen once");
	
	periodicSaveTimer = [NSTimer timerWithTimeInterval:20.0f target:self selector:@selector(periodicSave:) userInfo:nil repeats:YES];
	[[NSRunLoop mainRunLoop] addTimer:periodicSaveTimer forMode:NSRunLoopCommonModes];
	[[NSRunLoop mainRunLoop] addTimer:periodicSaveTimer forMode:NSEventTrackingRunLoopMode];
    //Setup timers, every half hour for DB maintenance, every night for Cache cleanup   
    maintenanceTimer = [NSTimer timerWithTimeInterval:30 * 60 
                                                target:self
                                              selector:@selector(storeMaintenance:)
                                              userInfo:nil
                                               repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:maintenanceTimer forMode:NSRunLoopCommonModes];
	[[NSRunLoop mainRunLoop] addTimer:maintenanceTimer forMode:NSEventTrackingRunLoopMode];
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:[NSDate date]];
    components.day = components.day - 1;
    components.hour = 23;
    components.minute = 59;
    lastImageCheck = [[NSCalendar currentCalendar] dateFromComponents:components];
    NSLog(@"Next image check no earlier than 24 hours from %@", lastImageCheck);
}

-(void)logNotificationWithDictionary:(NSDictionary*)noteDict
{
    
    BOOL deleteUponReturn = NO;
    GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
    NSString *appName = noteDict[GROWL_APP_NAME];
    NSString *hostName = noteDict[GROWL_NOTIFICATION_GNTP_SENT_BY];
    GrowlTicketDatabaseApplication *ticket = [[GrowlTicketDatabase sharedInstance] ticketForApplicationName:appName 
                                                                                                   hostName:hostName];
    GrowlTicketDatabaseNotification *notificationTicket = [ticket notificationTicketForName:noteDict[GROWL_NOTIFICATION_NAME]];
    
    BOOL logging = preferences.isGrowlHistoryLogEnabled;
    BOOL appLogging = ticket.loggingEnabled.boolValue;
    BOOL noteLogging = notificationTicket.loggingEnabled.boolValue;
    
    BOOL dontLog = (!logging || !appLogging || !noteLogging);
    
    BOOL isAway = [GrowlIdleStatusObserver sharedObserver].isIdle;
    if(notificationsWhileAway || historyWindow.window.visible)
        isAway = YES;
    //If the rollup isn't enabled, we aren't away, check last
    if(!preferences.isRollupEnabled)
        isAway = NO;
    
    if(!self.managedObjectContext)
    {
        NSLog(@"If we can't find/create the database, we can't log, return");
        return;
    }
    
    /* Ignore the notification if we arent logging and arent idle
     * Note that this breaks growl menu most recent notifications
     */
    if(dontLog){
        if(!isAway){
            //NSLog(@"We arent logging, and we arent away, return");
            return;
        }else{
            if(!preferences.retainAllNotesWhileAway){
                //NSLog(@"We are away, but not logging or retaining, or rollup is disabled, return");
                return;
            }else{
                //NSLog(@"We are away, shouldnt log this message, and we are rolling up, mark for deletion upon return");
                deleteUponReturn = YES;
            }
        }
    }
    
    void (^logBlock)(void) = ^{
        // NSError *error = nil;
        GrowlHistoryNotification *notification = [NSEntityDescription insertNewObjectForEntityForName:@"Notification" 
                                                                               inManagedObjectContext:managedObjectContext];
        
        // Whatever notification we set above, set its values and save
        [notification setWithNoteDictionary:noteDict];
        notification.deleteUponReturn = @(deleteUponReturn);
        notification.showInRollup = @(isAway);
    };
    if(![NSThread currentThread].isMainThread)
        [managedObjectContext performBlockAndWait:logBlock];
    else
        logBlock();
    //[self saveDatabase:NO];
    
    if(isAway)
    {
        notificationsWhileAway = YES;
        if(!preferences.squelchMode && preferences.isRollupAutomatic)
            [preferences setRollupShown:YES];
    }
}

-(void)showRollup
{
    if(![GrowlPreferencesController sharedController].isRollupEnabled)
        return;
    
    if(!historyWindow.window.visible)
    {
        [historyWindow resetArray];
        [historyWindow showWindow:self];
    }
}

-(void)hideRollup
{
    if(historyWindow.window.visible)
        [historyWindow close];
}

@end
