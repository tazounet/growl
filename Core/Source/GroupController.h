//
//  GroupController.h
//  Growl
//
//  Created by Daniel Siemer on 8/13/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GroupedArrayController;

@interface GroupController : NSObject

@property (nonatomic, weak) GroupedArrayController *owner;
@property (nonatomic, strong) NSString *groupID;
@property (nonatomic, strong) NSArrayController *groupArray;
@property (nonatomic) BOOL showGroup;

-(id)initWithGroupID:(NSString*)newID arrayController:(NSArrayController*)controller;

@end
