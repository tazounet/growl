//
//  HWGrowlGraphicCardMonitor.h
//  HardwareGrowler
//
//  Created by Jerome Chauvin on 5/31/14.
//

#import <Foundation/Foundation.h>
#import "HardwareGrowlPlugin.h"
#include "GSGPU.h"

@interface HWGrowlGraphicCardMonitor : NSObject <HWGrowlPluginProtocol, HWGrowlPluginNotifierProtocol, GSGPUDelegate>

@end
