//
//  HWGrowlPowerMonitor.h
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/6/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HardwareGrowlPlugin.h"

typedef NS_ENUM (NSInteger, HGPowerSource) {
	HGUnknownPower = -1,
	HGACPower = 0,
	HGBatteryPower,
	HGUPSPower
};

@interface HWGrowlPowerMonitor : NSObject <HWGrowlPluginProtocol, HWGrowlPluginNotifierProtocol>

@property (nonatomic, strong) IBOutlet NSView *prefsView;

@end
