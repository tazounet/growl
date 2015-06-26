//
//  GrowlTicketDatabasePlugin.h
//  Growl
//
//  Created by Daniel Siemer on 3/2/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface GrowlTicketDatabasePlugin : NSManagedObject

@property (nonatomic, strong) id configuration;
@property (nonatomic, strong) NSString * pluginID;
@property (nonatomic, strong) NSString * displayName;
@property (nonatomic, strong) NSString * configID;
@property (nonatomic, strong) NSString * pluginType;

-(BOOL)canFindInstance;
-(GrowlPlugin*)pluginInstanceForConfiguration;

@end
