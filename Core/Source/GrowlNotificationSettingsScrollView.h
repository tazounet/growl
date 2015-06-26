//
//  GrowlNotificationSettingsScrollView.h
//  Growl
//
//  Created by Daniel Siemer on 1/18/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface GrowlNotificationTableFadeView : NSView 
@property (nonatomic, strong) NSGradient *gradient;
@property (nonatomic) CGFloat angle;
@end

@interface GrowlNotificationSettingsScrollView : NSScrollView
@property (nonatomic, strong) GrowlNotificationTableFadeView *top;
@property (nonatomic, strong) GrowlNotificationTableFadeView *bottom;
@end
