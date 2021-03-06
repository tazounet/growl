//
//  GrowlFadingWindowTransition.m
//  Growl
//
//  Created by Ofri Wolfus on 27/07/05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import <GrowlPlugins/GrowlFadingWindowTransition.h>

@implementation GrowlFadingWindowTransition

#pragma mark -

- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(NSAnimationProgress)inProgress {
	if (aWindow) {
		switch (direction) {
			case GrowlForwardTransition:
				aWindow.alphaValue = inProgress;
				break;
			case GrowlReverseTransition:
				aWindow.alphaValue = (1.0 - inProgress);
				break;
			default:
				break;
		}
	}
}

@end
