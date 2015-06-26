//
//  HWGrowlVolumeMonitor.h
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/3/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HardwareGrowlPlugin.h"

@interface VolumeInfo : NSObject {
	NSData *iconData;
	NSString *name;
	NSString *path;
}

@property (nonatomic, strong) NSData *iconData;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *path;

+ (VolumeInfo *) volumeInfoForMountWithPath:(NSString *)aPath;
+ (VolumeInfo *) volumeInfoForUnmountWithPath:(NSString *)aPath;

- (id) initForMountWithPath:(NSString *)aPath;
- (id) initForUnmountWithPath:(NSString *)aPath;
- (id) initWithPath:(NSString *)aPath;

@end

@interface HWGrowlVolumeMonitor : NSObject <HWGrowlPluginProtocol, HWGrowlPluginNotifierProtocol, NSTableViewDelegate>

@property (nonatomic, strong) IBOutlet NSView *prefsView;

@end
