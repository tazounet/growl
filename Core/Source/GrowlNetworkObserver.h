//
//  GrowlNetworkObserver.h
//  Growl
//
//  Created by Daniel Siemer on 12/13/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PrimaryIPChangeNotification @"PrimaryIPChanged"
#define IPAddressesUpdateNotification @"IPAddressesUpdateNotification"

@interface GrowlNetworkObserver : NSObject

@property (nonatomic, strong) NSString *primaryIP;
@property (nonatomic, strong) NSArray *routableArray;
@property (nonatomic, strong) NSString *routableCombined;

+(GrowlNetworkObserver*)sharedObserver;

-(void)startObserving;
-(void)stopObserving;

-(void)updateAddresses;

@end
