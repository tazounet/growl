//
//  GrowlSmokeWindowView.m
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004–2011 The Growl Project. All rights reserved.
//

#import "GrowlSmokeWindowView.h"
#import "GrowlSmokeDefines.h"
#import "GrowlDefinesInternal.h"
#import "GrowlImageAdditions.h"
#import "NSMutableAttributedStringAdditions.h"
#import <WebKit/WebPreferences.h>

#define GrowlSmokeTextAreaWidth (GrowlSmokeNotificationWidth - GrowlSmokePadding - iconSize - GrowlSmokeIconTextPadding - GrowlSmokePadding)
#define GrowlSmokeMinTextHeight	(GrowlSmokePadding + iconSize + GrowlSmokePadding)

@interface ISProgressIndicator : NSProgressIndicator {
}
@end
@implementation ISProgressIndicator
- (void) startAnimation:(id)sender {
}
- (void) stopAnimation:(id)sender {
}
- (void) animate:(id)sender {
}
@end

@implementation GrowlSmokeWindowView

- (instancetype) initWithFrame:(NSRect)frame configurationDict:(NSDictionary*)configDict {
	if ((self = [super initWithFrame:frame])) {
		textFont = [NSFont systemFontOfSize:GrowlSmokeTextFontSize];
		textLayoutManager = [[NSLayoutManager alloc] init];
		titleLayoutManager = [[NSLayoutManager alloc] init];
		lineHeight = [textLayoutManager defaultLineHeightForFont:textFont];
		textShadow = [[NSShadow alloc] init];
		textShadow.shadowOffset = NSMakeSize(0.0, -2.0);
		textShadow.shadowBlurRadius = 3.0;

		int size = GrowlSmokeSizePrefDefault;
		if([configDict valueForKey:GrowlSmokeSizePref]){
			size = [[configDict valueForKey:GrowlSmokeSizePref] intValue];
		}
		if (size == GrowlSmokeSizeLarge)
			iconSize = GrowlSmokeIconSizeLarge;
		else
			iconSize = GrowlSmokeIconSize;
	}
	return self;
}

- (void) setProgress:(NSNumber *)value {
	if (value) {
		if (!progressIndicator) {
			progressIndicator = [[ISProgressIndicator alloc] initWithFrame:NSMakeRect(GrowlSmokePadding, GrowlSmokePadding + iconSize + GrowlSmokeIconProgressPadding, iconSize, NSProgressIndicatorPreferredSmallThickness)];
			progressIndicator.style = NSProgressIndicatorBarStyle;
			progressIndicator.controlSize = NSControlSizeSmall;
			[progressIndicator setBezeled:NO];
			progressIndicator.controlTint = NSDefaultControlTint;
			[progressIndicator setIndeterminate:NO];
			[self addSubview:progressIndicator];
		}
		progressIndicator.doubleValue = value.doubleValue;
		[self setNeedsDisplay:YES];
	} else if (progressIndicator) {
		[progressIndicator removeFromSuperview];
		progressIndicator = nil;
	}
}


- (BOOL) isFlipped {
	// Coordinates are based on top left corner
    return YES;
}

- (void) drawRect:(NSRect)rect {
	NSRect b = self.bounds;
	CGRect bounds = CGRectMake(b.origin.x, b.origin.y, b.size.width, b.size.height);

	// calculate bounds based on icon-float pref on or off
	CGRect shadedBounds;
	BOOL floatIcon = GrowlSmokeFloatIconPrefDefault;
	if([self.configurationDict valueForKey:GrowlSmokeFloatIconPref]){
		floatIcon = [[self.configurationDict valueForKey:GrowlSmokeFloatIconPref] boolValue];
	}
	if (floatIcon) {
		CGFloat sizeReduction = GrowlSmokePadding + iconSize + (GrowlSmokeIconTextPadding * 0.5);

		shadedBounds = CGRectMake(bounds.origin.x + sizeReduction + 1.0,
								  bounds.origin.y + 1.0,
								  bounds.size.width - sizeReduction - 2.0,
								  bounds.size.height - 2.0);
	} else {
		shadedBounds = CGRectInset(bounds, 1.0, 1.0);
	}

	// set up bezier path for rounded corners
    NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRoundedRect:shadedBounds xRadius:GrowlSmokeBorderRadius yRadius:GrowlSmokeBorderRadius];
	bezierPath.lineWidth = 2.0f;

	// draw background
	if (mouseOver) {
		[bgColor setFill];
		[textColor setStroke];
        [bezierPath fill];
        [bezierPath stroke];
	} else {
		[bgColor set];
        [bezierPath fill];
	}

	// draw the title and the text
	NSRect drawRect;
	drawRect.origin.x = GrowlSmokePadding;
	drawRect.origin.y = GrowlSmokePadding;
	drawRect.size.width = iconSize;
	drawRect.size.height = iconSize;

	[icon drawScaledInRect:drawRect
				 operation:NSCompositingOperationSourceOver
				  fraction:1.0
                neverFlipped:YES];

	drawRect.origin.x += iconSize + GrowlSmokeIconTextPadding;
    
    [NSGraphicsContext saveGraphicsState];
    //we do this because we don't want 10.7 helping us.
    CGContextSetShouldSmoothFonts([NSGraphicsContext currentContext].graphicsPort, false);
	if (haveTitle) {
		[titleLayoutManager drawGlyphsForGlyphRange:titleRange atPoint:drawRect.origin];
		drawRect.origin.y += titleHeight + GrowlSmokeTitleTextPadding;
	}

	if (haveText)
		[textLayoutManager drawGlyphsForGlyphRange:textRange atPoint:drawRect.origin];
    
    [NSGraphicsContext restoreGraphicsState];
	[self.window invalidateShadow];
	[super drawRect:rect];
}

- (void) setIcon:(NSImage *)anIcon {
	icon = anIcon;
	[self setNeedsDisplay:YES];
}

- (void) setTitle:(NSString *)aTitle {
	haveTitle = aTitle.length != 0;

	if (!haveTitle) {
		[self setNeedsDisplay:YES];
		return;
	}

	if (!titleStorage) {
		NSSize containerSize;
		containerSize.width = GrowlSmokeTextAreaWidth;
		containerSize.height = FLT_MAX;
		titleStorage = [[NSTextStorage alloc] init];
		titleContainer = [[NSTextContainer alloc] initWithContainerSize:containerSize];
        [titleLayoutManager addTextContainer:titleContainer];	// retains textContainer
		[titleStorage addLayoutManager:titleLayoutManager];	// retains layoutManager
		titleContainer.lineFragmentPadding = 0.0;
	}

	// construct attributes for the title
	NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
	NSFont *titleFont = [NSFont boldSystemFontOfSize:GrowlSmokeTitleFontSize];
	NSDictionary *defaultAttributes = @{NSFontAttributeName: titleFont,
		NSForegroundColorAttributeName: textColor,
		NSShadowAttributeName: textShadow,
		NSParagraphStyleAttributeName: paragraphStyle};

	[titleStorage.mutableString setString:aTitle];
	[titleStorage setAttributes:defaultAttributes range:NSMakeRange(0U, aTitle.length)];


	titleRange = [titleLayoutManager glyphRangeForTextContainer:titleContainer];	// force layout
	titleHeight = [titleLayoutManager usedRectForTextContainer:titleContainer].size.height;

	[self setNeedsDisplay:YES];
}

- (void) setText:(NSString *)aText {
	haveText = aText.length != 0;

	if (!haveText) {
		[self setNeedsDisplay:YES];
		return;
	}

	if (!textStorage) {
		NSSize containerSize;
		BOOL limitPref = GrowlSmokeLimitPrefDefault;
		if([self.configurationDict valueForKey:GrowlSmokeLimitPref]){
			limitPref = [[self.configurationDict valueForKey:GrowlSmokeLimitPref] boolValue];
		}
		containerSize.width = GrowlSmokeTextAreaWidth;
		if (limitPref)
			containerSize.height = lineHeight * GrowlSmokeMaxLines;
		else
			containerSize.height = FLT_MAX;
		textStorage = [[NSTextStorage alloc] init];
		textContainer = [[NSTextContainer alloc] initWithContainerSize:containerSize];
		[textLayoutManager addTextContainer:textContainer];	// retains textContainer
		[textStorage addLayoutManager:textLayoutManager];	// retains layoutManager
		textContainer.lineFragmentPadding = 0.0;
	}

	// construct default attributes for the description text
	NSDictionary *defaultAttributes = @{NSFontAttributeName: textFont,
		NSForegroundColorAttributeName: textColor,
		NSShadowAttributeName: textShadow};

	[textStorage.mutableString setString:aText];
	[textStorage setAttributes:defaultAttributes range:NSMakeRange(0U, aText.length)];


	textRange = [textLayoutManager glyphRangeForTextContainer:textContainer];	// force layout
	textHeight = [textLayoutManager usedRectForTextContainer:textContainer].size.height;

	[self setNeedsDisplay:YES];
}

- (void) setPriority:(int)priority {
	NSString *key;
	NSString *textKey;
	switch (priority) {
		case -2:
			key = GrowlSmokeVeryLowColor;
			textKey = GrowlSmokeVeryLowTextColor;
			break;
		case -1:
			key = GrowlSmokeModerateColor;
			textKey = GrowlSmokeModerateTextColor;
			break;
		case 1:
			key = GrowlSmokeHighColor;
			textKey = GrowlSmokeHighTextColor;
			break;
		case 2:
			key = GrowlSmokeEmergencyColor;
			textKey = GrowlSmokeEmergencyTextColor;
			break;
		case 0:
		default:
			key = GrowlSmokeNormalColor;
			textKey = GrowlSmokeNormalTextColor;
			break;
	}

	CGFloat backgroundAlpha = GrowlSmokeAlphaPrefDefault;
	if([self.configurationDict valueForKey:GrowlSmokeAlphaPref]){
		backgroundAlpha = [[self.configurationDict valueForKey:GrowlSmokeAlphaPref] floatValue];
	}
	backgroundAlpha *= 0.01;


	Class NSDataClass = [NSData class];
	NSData *data = [self.configurationDict valueForKey:key];

	if (data && [data isKindOfClass:NSDataClass]) {
		bgColor = [NSUnarchiver unarchiveObjectWithData:data];
		bgColor = [bgColor colorWithAlphaComponent:backgroundAlpha];
	} else {
		bgColor = [NSColor colorWithCalibratedWhite:0.1 alpha:backgroundAlpha];
	}
	data = nil;

	data = [self.configurationDict valueForKey:textKey];
	if (data && [data isKindOfClass:NSDataClass]) {
		textColor = [NSUnarchiver unarchiveObjectWithData:data];
	} else {
		textColor = [NSColor whiteColor];
	}
	data = nil;
	
	textShadow.shadowColor = [bgColor blendedColorWithFraction:0.5 ofColor:[NSColor blackColor]];
}

- (void) sizeToFit {
	CGFloat height = GrowlSmokePadding + GrowlSmokePadding + self.titleHeight + self.descriptionHeight;
	if (haveTitle && haveText)
		height += GrowlSmokeTitleTextPadding;
	if (progressIndicator)
		height += GrowlSmokeIconProgressPadding + progressIndicator.bounds.size.height;
	if (height < GrowlSmokeMinTextHeight)
		height = GrowlSmokeMinTextHeight;

	NSRect rect = self.frame;
	rect.size.height = height;
	self.frame = rect;

	// resize the window so that it contains the tracking rect
	NSWindow *window = self.window;
	NSRect windowRect = window.frame;
	windowRect.origin.y -= height - windowRect.size.height;
	windowRect.size.height = height;
	[window setFrame:windowRect display:YES animate:YES];

	if (trackingRectTag)
		[self removeTrackingRect:trackingRectTag];
	trackingRectTag = [self addTrackingRect:rect owner:self userData:NULL assumeInside:NO];
}

- (CGFloat) titleHeight {
	return haveTitle ? titleHeight : 0.0;
}

- (CGFloat) descriptionHeight {
	return haveText ? textHeight : 0.0;
}

- (NSInteger) descriptionRowCount {
	NSInteger rowCount = textHeight / lineHeight;
	BOOL limitPref = GrowlSmokeLimitPrefDefault;
	if([self.configurationDict valueForKey:GrowlSmokeLimitPref]){
		limitPref = [[self.configurationDict valueForKey:GrowlSmokeLimitPref] boolValue];
	}
	if (limitPref)
		return MIN(rowCount, GrowlSmokeMaxLines);
	else
		return rowCount;
}

#pragma mark -

- (id) target {
	return target;
}

- (void) setTarget:(id) object {
	target = object;
}

#pragma mark -

- (SEL) action {
	return action;
}

- (void) setAction:(SEL) selector {
	action = selector;
}

@end
