//
//  GrowlNotificationView.m
//  Growl
//
//  Created by Jamie Kirkpatrick on 27/11/05.
//  Copyright 2005-2006  Jamie Kirkpatrick. All rights reserved.
//

#import <GrowlPlugins/GrowlNotificationView.h>
#import "GrowlDefinesInternal.h"
#import "NSViewAdditions.h"
#import "GrowlNotification.h"

@implementation GrowlNotificationView

@synthesize target;
@synthesize action;

- (instancetype) init {
	if( (self = [super init ]) ) {
		closeBoxOrigin = NSMakePoint(0,0);
	}
	return self;
}

- (instancetype) initWithFrame:(NSRect)frameRect {
	if((self = [super initWithFrame:frameRect])){
		NSDictionary *bundleDict = [NSBundle bundleForClass:[self class]].infoDictionary;
		CGFloat xOrig = 0;
		CGFloat yOrig = 0;
		if(bundleDict[@"GrowlCloseButtonXOrigin"])
			xOrig = [bundleDict[@"GrowlCloseButtonXOrigin"] floatValue];
		if(bundleDict[@"GrowlCloseButtonYOrigin"])
			yOrig = [bundleDict[@"GrowlCloseButtonYOrigin"] floatValue];
		
		closeBoxOrigin = NSMakePoint(xOrig,yOrig);
	}
	return self;
}

#pragma mark -

- (BOOL) shouldDelayWindowOrderingForEvent:(NSEvent *)theEvent {
	[NSApp preventWindowOrdering];
	return YES;
}

- (BOOL) mouseOver {
	return mouseOver;
}

- (void) setCloseOnMouseExit:(BOOL)flag {
	closeOnMouseExit = flag;
}

- (BOOL) acceptsFirstMouse:(NSEvent *)theEvent {
	return YES;
}

- (void) mouseEntered:(NSEvent *)theEvent {
    [self setCloseBoxVisible:YES];
	mouseOver = YES;
	[self setNeedsDisplay:YES];
	
	if ([self.window.windowController respondsToSelector:@selector(mouseEnteredNotificationView:)])
		[self.window.windowController performSelector:@selector(mouseEnteredNotificationView:)
											   withObject:self];
}

- (void) mouseExited:(NSEvent *)theEvent {
	mouseOver = NO;
    [self setCloseBoxVisible:NO];
	[self setNeedsDisplay:YES];
	
	// abuse the target object
	if (closeOnMouseExit) {
		if ([self.window.windowController respondsToSelector:@selector(stopDisplay)])
			[self.window.windowController performSelector:@selector(stopDisplay)];
	}
	
	if ([self.window.windowController respondsToSelector:@selector(mouseExitedNotificationView:)])
		[self.window.windowController performSelector:@selector(mouseExitedNotificationView:)
											   withObject:self];
}

- (void) mouseUp:(NSEvent *)event {
	if(event.clickCount == 1) {
        mouseOver = NO;

        if (target && action && [target respondsToSelector:action])
            [target performSelector:action withObject:self];
    }
}

- (void)rightMouseUp:(NSEvent *)theEvent {
    [self clickedCloseBox:self];
}

static NSMutableDictionary *buttonDict = nil;
static NSButton *gCloseButton = nil;
+ (void)initialize {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		buttonDict = [[NSMutableDictionary alloc] init];
		gCloseButton = [[NSButton alloc] initWithFrame:NSMakeRect(0,0,30,30)];
		gCloseButton.bezelStyle = NSRegularSquareBezelStyle;
		[gCloseButton setBordered:NO];
		[gCloseButton setButtonType:NSMomentaryChangeButton];
		gCloseButton.imagePosition = NSImageOnly;
		gCloseButton.image = [NSImage imageNamed:@"closebox"];
		gCloseButton.alternateImage = [NSImage imageNamed:@"closebox_pressed"];
	});
}

+ (NSButton *) closeButton {
	return gCloseButton;
}

+ (NSButton *) closeButtonForKey:(NSString*)key {
	NSButton *result = nil;
	if(key && buttonDict){
		result = [buttonDict valueForKey:key];
	}
	if(!result){
		result = gCloseButton;
	}
	return result;
}

+ (void)makeButtonWithImage:(NSImage*)image pressedImage:(NSImage*)pressed forKey:(NSString*)key {
	if(key && (image || pressed)){
		//If the button is equal to the global close button, it means we don't have a custom one for that key yet
		if([self closeButtonForKey:key] == gCloseButton){
			NSButton *button = [[NSButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 30.0, 30.0)];
			button.bezelStyle = NSRegularSquareBezelStyle;
			[button setBordered:NO];
			[button setButtonType:NSMomentaryChangeButton];
			button.imagePosition = NSImageOnly;
			button.image = image ? image : [NSImage imageNamed:@"closebox"];
			button.alternateImage = pressed ? pressed : [NSImage imageNamed:@"closebox_pressed"];
			[self setButton:button forKey:key];
		}
	}
}

+ (void)setButton:(NSButton*)button forKey:(NSString*)key {
	if(key && button){
		buttonDict[key] = button;
	}
}

- (BOOL) showsCloseBox {
	return YES;
}

- (void) clickedCloseBox:(id)sender {
	mouseOver = NO;
	if ([self.window.windowController respondsToSelector:@selector(clickedCloseBox)])
		[self.window.windowController performSelector:@selector(clickedCloseBox)];

	/* NSButton can mess up our display in its rect after mouseUp,
	 * so do a re-display on the next run loop.
	 */
	[self performSelector:@selector(display)
				  withObject:nil
				  afterDelay:0
					  inModes:@[NSRunLoopCommonModes, NSEventTrackingRunLoopMode]];
	
	if ((NSApp.currentEvent.modifierFlags & NSEventModifierFlagOption) != 0) {
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_CLOSE_ALL_NOTIFICATIONS
															object:nil];
	}
}

- (void) setCloseBoxVisible:(BOOL)yorn {
	if (self.showsCloseBox) {
		NSButton *button = [GrowlNotificationView closeButtonForKey:self.buttonKey];
		button.target = self;
		button.action = @selector(clickedCloseBox:);
		[button setFrameOrigin:closeBoxOrigin];
		if(yorn)
			[self addSubview:button];
		else 
			[button removeFromSuperview];
	}
}

- (void) setCloseBoxOrigin:(NSPoint)inOrigin {
	closeBoxOrigin = inOrigin;
}

- (void)drawRect:(NSRect)rect
{
	if(!initialDisplayTest) {
		initialDisplayTest = YES;
		if(self.showsCloseBox && NSPointInRect([self convertPointFromScreen:[NSEvent mouseLocation]], self.frame))
			[self mouseEntered:[[NSEvent alloc]init]];
	}
	[super drawRect:rect];
}

#pragma mark For subclasses
- (void) setPriority:(int)priority {
}
- (void) setTitle:(NSString *) aTitle {
}
- (void) setText:(NSString *)aText {
}
- (void) setIcon:(NSImage *)anIcon {
}
- (void) sizeToFit {};

-(NSDictionary*)configurationDict {
	if([self.window.windowController respondsToSelector:@selector(configurationDict)])
		return [self.window.windowController performSelector:@selector(configurationDict)];
	return nil;
}

-(NSString*)buttonKey {
	return [NSBundle bundleForClass:[self class]].bundleIdentifier;
}

- (void) mouseEnteredNotificationView:(GrowlNotificationView *)notificationView {
}

- (void) mouseExitedNotificationView:(GrowlNotificationView *)notificationView {
}

- (void) stopDisplay {
}

- (void) clickedCloseBox {
}

@end
