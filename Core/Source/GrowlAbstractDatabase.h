//
//  GrowlAbstractDatabase.h
//  Growl
//
//  Created by Daniel Siemer on 9/23/10.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define RemoteDatabaseDidUpdate @"RemoteDatabaseDidUpdate"

@interface GrowlAbstractDatabase : NSObject {
   NSPersistentStoreCoordinator *persistentStoreCoordinator;
   NSManagedObjectModel *managedObjectModel;
   NSManagedObjectContext *managedObjectContext;
   
}

@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

-(NSString*)storeType;
-(NSString*)storePath;
-(NSString*)modelName;
-(void)databaseDidSave:(NSNotification*)note;
-(void)databaseDidChange:(NSNotification*)note;
-(void)saveDatabase:(BOOL)doItNow;

@end
