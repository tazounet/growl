//
//  GrowlWebKitDisplayPlugin.h
//  Growl
//
//  Created by JKP on 13/11/2005.
//	Copyright 2005–2011 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <GrowlPlugins/GrowlDisplayPlugin.h>

@interface GrowlWebKitDisplayPlugin : GrowlDisplayPlugin {
	NSString    *style;
}

- (instancetype) initWithName:(NSString *)name author:(NSString *)author version:(NSString *)version pathname:(NSString *)pathname NS_UNAVAILABLE;
- (instancetype) initWithStyleBundle:(NSBundle *)styleBundle;

@end
