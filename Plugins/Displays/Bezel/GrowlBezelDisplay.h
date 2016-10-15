//
//  GrowlBezelDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <GrowlPlugins/GrowlDisplayPlugin.h>

@interface GrowlBezelDisplay : GrowlDisplayPlugin {
}

- (instancetype) initWithName:(NSString *)name author:(NSString *)author version:(NSString *)version pathname:(NSString *)pathname NS_UNAVAILABLE;

- (instancetype) init;

@end
