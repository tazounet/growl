//
//  GSMux.h
//  gfxCardStatus
//
//  Created by Cody Krieger on 6/21/11.
//  Copyright 2011 Cody Krieger. All rights reserved.
//

typedef NS_ENUM (NSInteger, GSSwitcherMode) {
    GSSwitcherModeForceIntegrated,
    GSSwitcherModeForceDiscrete,
    GSSwitcherModeDynamicSwitching,
    GSSwitcherModeToggleGPU
};

#define kDriverClassName "AppleGraphicsControl"

@interface GSMux : NSObject

// Switching driver initialization and cleanup routines.
+ (BOOL)switcherOpen;
+ (void)switcherClose;

+ (BOOL)isUsingIntegratedGPU;
+ (BOOL)isUsingDiscreteGPU;
+ (BOOL)isUsingDynamicSwitching;
// Whether or not a machine is using the old-style "you must log out first"
// switching policy or not. We kick machines into said policy when we switch to
// Integrated Only or Discrete Only for reliability and consistency purposes.
+ (BOOL)isUsingOldStyleSwitchPolicy;

+ (BOOL)isOnIntegratedOnlyMode;
+ (BOOL)isOnDiscreteOnlyMode;

@end
