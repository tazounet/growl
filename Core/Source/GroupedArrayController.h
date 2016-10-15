//
//  GroupedArrayController.h
//  Growl
//
//  Created by Daniel Siemer on 7/29/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import <AppKit/AppKit.h>

@class GrowlNotificationDatabase, GroupedArrayController;

@protocol GroupedArrayControllerDelegate <NSObject>
@optional
-(void)groupedControllerUpdatedTotalCount:(GroupedArrayController*)groupedController;
-(void)groupedControllerBeginUpdates:(GroupedArrayController*)groupedController;
-(void)groupedControllerEndUpdates:(GroupedArrayController*)groupedController;
-(void)groupedController:(GroupedArrayController*)groupedController insertIndexes:(NSIndexSet*)indexSet;
-(void)groupedController:(GroupedArrayController*)groupedController removeIndexes:(NSIndexSet*)indexSet;
-(void)groupedController:(GroupedArrayController*)groupedController moveIndex:(NSUInteger)start toIndex:(NSUInteger)end;

@end

@interface GroupedArrayController : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithEntityName:(NSString*)entity
               basePredicateString:(NSString*)predicate
                          groupKey:(NSString*)key
              managedObjectContext:(NSManagedObjectContext*)aContext NS_DESIGNATED_INITIALIZER;

@property (nonatomic, unsafe_unretained) id<GroupedArrayControllerDelegate> delegate;
@property (nonatomic, unsafe_unretained) NSManagedObjectContext *context;
@property (nonatomic, weak) NSTableView *tableView; 
@property (nonatomic, strong) NSPredicate *filterPredicate; 
@property (nonatomic, strong) NSString *entityName;
@property (nonatomic, strong) NSString *basePredicateString;
@property (nonatomic, strong) NSString *groupKey;
@property (nonatomic, strong) NSMutableArray *currentGroups;
@property (nonatomic, strong) NSMutableDictionary *groupControllers;
@property (nonatomic, strong) NSArrayController *countController;
@property (nonatomic, strong) NSArray *arrangedObjects;
@property (nonatomic, copy) NSComparator groupCompareBlock;
@property (nonatomic, strong) id selection;
@property (nonatomic) BOOL grouped;
@property (nonatomic) BOOL doNotShowSingleGroupHeader;
@property (nonatomic) BOOL showEmptyGroups;
@property (nonatomic) BOOL transitionGroup;

-(NSArray*)arrangedObjects;
-(void)toggleGrouped;
-(void)toggleShowGroup:(NSString*)groupID;
-(NSArray*)updatedArray;
-(void)updateArray;
-(void)updateArrayGroups;

-(NSUInteger)indexOfFirstNonGroupItem;
-(id)selection;
-(NSArray*)selectedObjects;

-(void)updatedTotalCount;
-(void)beginUpdates;
-(void)endUpdates;
-(void)insertIndexes:(NSIndexSet*)indexSet;
-(void)removeIndexes:(NSIndexSet*)indexSet;
-(void)moveIndex:(NSUInteger)start toIndex:(NSUInteger)end;


@end
