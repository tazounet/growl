//
//  GrowlSmokeWindowController.m
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004–2011 The Growl Project. All rights reserved.
//
//  Most of this is lifted from KABubbleWindowController in the Growl source

#import <GrowlPlugins/GrowlNotification.h>
#import <GrowlPlugins/GrowlWindowtransition.h>
#import <GrowlPlugins/GrowlFadingWindowTransition.h>
#import "GrowlSmokeWindowController.h"
#import "GrowlSmokeWindowView.h"
#import "GrowlSmokeDefines.h"
#import "GrowlDefinesInternal.h"

@implementation GrowlSmokeWindowController

//static const double gAdditionalLinesDisplayTime = 0.5;
//static const double gMaxDisplayTime = 10.0;

- (instancetype) initWithNotification:(GrowlNotification*)note plugin:(GrowlDisplayPlugin *)aPlugin {
	NSDictionary *configDict = note.configurationDict;
	
	screenNumber = 0U;
	if([configDict valueForKey:GrowlSmokeScreenPref]){
		screenNumber = [[configDict valueForKey:GrowlSmokeScreenPref] unsignedIntValue];
	}
	NSArray *screens = [NSScreen screens];
	NSUInteger screensCount = screens.count;
	if (screensCount) {
		self.screen = ((screensCount >= (screenNumber + 1)) ? screens[screenNumber] : screens[0]);
	}

	NSTimeInterval duration = GrowlSmokeDurationPrefDefault;
	if([configDict valueForKey:GrowlSmokeDurationPref]){
		duration = [[configDict valueForKey:GrowlSmokeDurationPref] floatValue];
	}
	self.displayDuration = duration;

	NSPanel *panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0.0, 0.0, GrowlSmokeNotificationWidth, 65.0)
												styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel
												  backing:NSBackingStoreBuffered
													defer:YES];
	NSRect panelFrame = panel.frame;
	[panel setBecomesKeyOnlyIfNeeded:YES];
	[panel setHidesOnDeactivate:NO];
	panel.backgroundColor = [NSColor clearColor];
	[panel setLevel:GrowlVisualDisplayWindowLevel];
	panel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
	panel.alphaValue = 0.0;
	[panel setOpaque:NO];
	[panel setHasShadow:YES];
	[panel setCanHide:NO];
	[panel setOneShot:YES];

	GrowlSmokeWindowView *view = [[GrowlSmokeWindowView alloc] initWithFrame:panelFrame configurationDict:configDict];
	view.target = self;
	view.action = @selector(notificationClicked:);
	panel.contentView = view;

	// call super so everything else is set up...
	if ((self = [super initWithWindow:panel andPlugin:aPlugin])) {
		// set up the transitions...
		GrowlFadingWindowTransition *fader = [[GrowlFadingWindowTransition alloc] initWithWindow:panel];
		[self addTransition:fader];
		[self setStartPercentage:0 endPercentage:100 forTransition:fader];
		[fader setAutoReverses:YES];
	}

	return self;
}

#pragma mark -
#pragma mark positioning methods

- (CGFloat) requiredDistanceFromExistingDisplays {
	return GrowlSmokePadding;
}

@end
