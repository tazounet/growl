//
//  GrowlWindowTransition.m
//  Growl
//
//  Created by Ofri Wolfus on 27/07/05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import <GrowlPlugins/GrowlWindowtransition.h>

@implementation GrowlWindowTransition

- (instancetype) initWithWindow:(NSWindow *)inWindow {
	return [self initWithWindow:inWindow direction:GrowlForwardTransition];
}

- (instancetype) initWithWindow:(NSWindow *)inWindow direction:(GrowlTransitionDirection)theDirection {
	if ((self = [super init])) {
		self.window = inWindow;
		self.direction = theDirection;
		self.animationBlockingMode = NSAnimationNonblocking;
	}

	return self;
}

//Only start if we have a window
- (void) startAnimation {
	if (!window)
		NSLog(@"Trying to start window transition with no window. Transition: %@", self);

	[super startAnimation];
}

- (void) stopAnimation {
	if (!window)
		NSLog(@"Trying to stop window transition with no window. Transition: %@", self);

	[super stopAnimation];
}

- (BOOL) autoReverses {
	return autoReverses;
}

- (void) setAutoReverses: (BOOL) flag {
	autoReverses = flag;
}

- (GrowlTransitionDirection) direction {
	return direction;
}

- (void)reverse {
	self.direction = ((self.direction == GrowlForwardTransition) ? GrowlReverseTransition : GrowlForwardTransition);
}

- (BOOL) didAutoReverse {
	return didAutoReverse;
}

- (void) setDidAutoReverse: (BOOL) flag {
	didAutoReverse = flag;
}

- (void) setDirection: (GrowlTransitionDirection) theDirection {
    direction = theDirection;
}

- (NSWindow *) window {
	return window;
}

- (void) setWindow:(NSWindow *)inWindow {
	if (inWindow != window) {
		window = inWindow;
	}
}


- (void)animationDidEnd
{
	if (!self.animating && self.autoReverses) {
		[self reverse];
		[self setDidAutoReverse:![self didAutoReverse]];
	}
}

- (void) setCurrentProgress:(NSAnimationProgress)progress {
	[self drawTransitionWithWindow:window progress:progress];
	
	super.currentProgress = progress;

	if (progress >= 1.0) {
		/* NSAnimation will notify the delegate in the next run loop; we want to trigger our own didEnd after that happens
		 * so we don't falsely appear to be reversed if we're supposed to autoreverse.
		 */
		[self performSelector:@selector(animationDidEnd)
					  withObject:nil
					  afterDelay:0
						  inModes:@[NSRunLoopCommonModes, NSEventTrackingRunLoopMode]];
	}
}

- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(NSAnimationProgress)progress {
	//
}

@end
