//
//  GrowlMusicVideoWindowController.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import <GrowlPlugins/GrowlFadingWindowTransition.h>
#import <GrowlPlugins/GrowlSlidingWindowTransition.h>
#import <GrowlPlugins/GrowlWipeWindowTransition.h>
#import <GrowlPlugins/GrowlNotification.h>
#import <GrowlPlugins/NSScreen+GrowlScreenAdditions.h>
#import "GrowlMusicVideoWindowController.h"
#import "GrowlMusicVideoWindowView.h"
#import "GrowlMusicVideoPrefs.h"

@implementation GrowlMusicVideoWindowController

- (instancetype) initWithNotification:(GrowlNotification *)note plugin:(GrowlDisplayPlugin *)aPlugin {
	NSDictionary *configDict = note.configurationDict;

	screenNumber = 0U;
	if([configDict valueForKey:MUSICVIDEO_SCREEN_PREF]){
		screenNumber = [[configDict valueForKey:MUSICVIDEO_SCREEN_PREF] intValue];
	}
	NSArray *screens = [NSScreen screens];
	NSUInteger screensCount = screens.count;
	if (screensCount) {
		self.screen = ((screensCount >= (screenNumber + 1)) ? screens[screenNumber] : screens[0]);
	}
	
	NSRect sizeRect;
	NSRect screen = self.screen.frame;
	int sizePref = MUSICVIDEO_SIZE_NORMAL;
	if([configDict valueForKey:MUSICVIDEO_SIZE_PREF]){
		sizePref = [[configDict valueForKey:MUSICVIDEO_SIZE_PREF] intValue];
	}
	sizeRect.origin = screen.origin;
	sizeRect.size.width = screen.size.width;
	if (sizePref == MUSICVIDEO_SIZE_HUGE)
		sizeRect.size.height = 192.0;
	else
		sizeRect.size.height = 96.0;
	frameHeight = sizeRect.size.height;

	NSPanel *panel = [[NSPanel alloc] initWithContentRect:sizeRect
												styleMask:NSWindowStyleMaskBorderless
												  backing:NSBackingStoreBuffered
													defer:YES];
	NSRect panelFrame = panel.frame;
	[panel setBecomesKeyOnlyIfNeeded:YES];
	[panel setHidesOnDeactivate:NO];
	panel.backgroundColor = [NSColor clearColor];
	[panel setLevel:GrowlVisualDisplayWindowLevel];
	[panel setIgnoresMouseEvents:YES];
	panel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
	[panel setOpaque:NO];
	[panel setHasShadow:NO];
	[panel setCanHide:NO];
	[panel setOneShot:YES];
	panel.delegate = self;

	GrowlMusicVideoWindowView *view = [[GrowlMusicVideoWindowView alloc] initWithFrame:panelFrame];

	view.target = self;
	view.action = @selector(notificationClicked:); // Not used for now

	panel.contentView = view; // retains subview

	[panel setFrameTopLeftPoint:screen.origin];

	// call super so everything else is set up...
	if ((self = [super initWithWindow:panel andPlugin:aPlugin])) {
		
		NSTimeInterval duration = GrowlMusicVideoDurationPrefDefault;
		if([configDict valueForKey:MUSICVIDEO_DURATION_PREF]){
			duration = [[configDict valueForKey:MUSICVIDEO_DURATION_PREF] floatValue];
		}
		self.displayDuration = duration;
		
		//The default duration for transitions is far too long for the music video effect.
		self.transitionDuration = 0.3;

		MusicVideoEffectType effect = MUSICVIDEO_EFFECT_SLIDE;
		if([configDict valueForKey:MUSICVIDEO_EFFECT_PREF]){
			effect = [[configDict valueForKey:MUSICVIDEO_EFFECT_PREF] intValue];
		}
		switch (effect)
		{
			case MUSICVIDEO_EFFECT_SLIDE:
			{
				//slider effect
				GrowlSlidingWindowTransition *slider = [[GrowlSlidingWindowTransition alloc] initWithWindow:panel];
				[slider setFromOrigin:NSMakePoint(NSMinX(screen),NSMinY(screen)-frameHeight) toOrigin:NSMakePoint(NSMinX(screen),NSMinY(screen))];
				[self setStartPercentage:0 endPercentage:100 forTransition:slider];
				[slider setAutoReverses:YES];
				[self addTransition:slider];
				break;
			}
			case MUSICVIDEO_EFFECT_FADING:
			{
				GrowlFadingWindowTransition *fader = [[GrowlFadingWindowTransition alloc] initWithWindow:panel];
				[self addTransition:fader];
				[self setStartPercentage:0 endPercentage:100 forTransition:fader];
				[fader setAutoReverses:YES];
				
				// I am adding in a sliding transition from screen,screen to screen,screen to make sure the window is properly positioned during the animation - swr
				GrowlSlidingWindowTransition *slider = [[GrowlSlidingWindowTransition alloc] initWithWindow:panel];
				[slider setFromOrigin:NSMakePoint(NSMinX(screen),NSMinY(screen)) toOrigin:NSMakePoint(NSMinX(screen),NSMinY(screen))];
				[self setStartPercentage:0 endPercentage:100 forTransition:slider];
				[slider setAutoReverses:YES];
				[self addTransition:slider];
				break;
			}
			case MUSICVIDEO_EFFECT_WIPE:
			{
				NSLog(@"Wipe not implemented");
				//wipe effect
				//[panel setFrameOrigin:NSMakePoint( 0, 0)];
				//GrowlWipeWindowTransition *wiper = [[GrowlWipeWindowTransition alloc] initWithWindow:panel];
				// save for scale effect [wiper setFromOrigin:NSMakePoint(0,0) toOrigin:NSMakePoint(NSMaxX(screen), frameHeight)];
				//[wiper setFromOrigin:NSMakePoint(NSMaxX(screen), 0) toOrigin:NSMakePoint(NSMaxX(screen), frameHeight)];
				//[self setStartPercentage:0 endPercentage:100 forTransition:wiper];
				//[wiper setAutoReverses:YES];
				//[self addTransition:wiper];
				//[wiper release];
				break;
			}
		}
	}
	
	
	return self;

}

-(CGPoint)idealOriginInRect:(CGRect)rect {
	return self.screen.frame.origin;
}

-(void)positionInRect:(CGRect)rect {
	[super positionInRect:rect];
	[self.window setFrameTopLeftPoint:self.screen.frame.origin];
}

-(NSString*)displayQueueKey {
	return [NSString stringWithFormat:@"musicvideo-%@", self.screen.screenIDString];
}

@end
