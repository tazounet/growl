//
//  GrowlBrushedWindowView.m
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004–2011 The Growl Project. All rights reserved.
//

#import "GrowlBrushedWindowView.h"
#import "GrowlBrushedDefines.h"
#import "GrowlDefinesInternal.h"
#import "GrowlImageAdditions.h"
#import "NSMutableAttributedStringAdditions.h"
#import <WebKit/WebPreferences.h>

#define GrowlBrushedTextAreaWidth	(GrowlBrushedNotificationWidth - GrowlBrushedPadding - iconSize - GrowlBrushedIconTextPadding - GrowlBrushedPadding)
#define GrowlBrushedMinTextHeight	(GrowlBrushedPadding + iconSize + GrowlBrushedPadding)

@implementation GrowlBrushedWindowView

- (instancetype) initWithFrame:(NSRect) frame configurationDict:(NSDictionary *)configDict{
	if ((self = [super initWithFrame:frame])) {
		textFont = [NSFont systemFontOfSize:GrowlBrushedTextFontSize];
		textLayoutManager = [[NSLayoutManager alloc] init];
		titleLayoutManager = [[NSLayoutManager alloc] init];
		lineHeight = [textLayoutManager defaultLineHeightForFont:textFont];
		textShadow = [[NSShadow alloc] init];
		textShadow.shadowOffset = NSMakeSize(0.0, -2.0);
		textShadow.shadowBlurRadius = 3.0;
		textShadow.shadowColor = [self.window.backgroundColor blendedColorWithFraction:0.5
																					 ofColor:[NSColor blackColor]];
        
		int size = GrowlBrushedSizePrefDefault;
		if([configDict valueForKey:GrowlBrushedSizePref]){
			size = [[configDict valueForKey:GrowlBrushedSizePref] intValue];
		}
		if (size == GrowlBrushedSizeLarge) {
			iconSize = GrowlBrushedIconSizeLarge;
		} else {
			iconSize = GrowlBrushedIconSize;
		}
	}
    
	return self;
}


- (BOOL)isFlipped {
	// Coordinates are based on top left corner
    return YES;
}

- (void) drawRect:(NSRect)rect {
	NSRect b = self.bounds;
	CGRect bounds = CGRectMake(b.origin.x, b.origin.y, b.size.width, b.size.height);
    
	CGContextRef context = (CGContextRef)[NSGraphicsContext currentContext].graphicsPort;
    
	// clear the window
	CGContextClearRect(context, bounds);
    
	// calculate bounds based on icon-float pref on or off
	CGRect shadedBounds;
	BOOL floatIcon = GrowlBrushedFloatIconPrefDefault;
	if([self.configurationDict valueForKey:GrowlBrushedFloatIconPref]){
		floatIcon = [[self.configurationDict valueForKey:GrowlBrushedFloatIconPref] boolValue];
	}
	if (floatIcon) {
		CGFloat sizeReduction = GrowlBrushedPadding + iconSize + (GrowlBrushedIconTextPadding * 0.5);
        
		shadedBounds = CGRectMake(bounds.origin.x + sizeReduction + 1.0,
								  bounds.origin.y + 1.0,
								  bounds.size.width - sizeReduction - 2.0,
								  bounds.size.height - 2.0);
	} else {
		shadedBounds = CGRectInset(bounds, 1.0, 1.0);
	}
    
	// set up path for rounded corners
    NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRoundedRect:shadedBounds xRadius:GrowlBrushedBorderRadius yRadius:GrowlBrushedBorderRadius];
	bezierPath.lineWidth = 2.0f;
    
	// draw background
	NSWindow *window = self.window;
	NSColor *bgColor = window.backgroundColor;
	if (mouseOver) {
		[bgColor setFill];
		[[NSColor keyboardFocusIndicatorColor] setStroke];
        
        [bezierPath fill];
        [bezierPath stroke];
	} else {
		[bgColor set];
        [bezierPath fill];
	}
    
	// draw the title and the text
	NSRect drawRect;
	drawRect.origin.x = GrowlBrushedPadding;
	drawRect.origin.y = GrowlBrushedPadding;
	drawRect.size.width = iconSize;
	drawRect.size.height = iconSize;

	[icon drawScaledInRect:drawRect
				 operation:NSCompositingOperationSourceOver
				  fraction:1.0
                 neverFlipped:YES];
    
	drawRect.origin.x += iconSize + GrowlBrushedIconTextPadding;
    
	if (haveTitle) {
		[titleLayoutManager drawGlyphsForGlyphRange:titleRange atPoint:drawRect.origin];
		drawRect.origin.y += titleHeight + GrowlBrushedTitleTextPadding;
	}
    
	if (haveText)
		[textLayoutManager drawGlyphsForGlyphRange:textRange atPoint:drawRect.origin];
    
	[window invalidateShadow];
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
		containerSize.width = GrowlBrushedTextAreaWidth;
		containerSize.height = FLT_MAX;
		titleStorage = [[NSTextStorage alloc] init];
		titleContainer = [[NSTextContainer alloc] initWithContainerSize:containerSize];
		[titleLayoutManager addTextContainer:titleContainer];	// retains textContainer
		[titleStorage addLayoutManager:titleLayoutManager];	// retains layoutManager
		titleContainer.lineFragmentPadding = 0.0;
	}
    
	// construct attributes for the title
	NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	NSFont *titleFont = [NSFont boldSystemFontOfSize:GrowlBrushedTitleFontSize];
	paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
	NSDictionary *defaultAttributes = @{NSFontAttributeName: titleFont,
                                       NSForegroundColorAttributeName: textColor,
                                       NSShadowAttributeName: textShadow,
                                       NSParagraphStyleAttributeName: paragraphStyle};
    
	[titleStorage.mutableString setString:aTitle];
	[titleStorage setAttributes:defaultAttributes range:NSMakeRange(0, titleStorage.length)];
    
    
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
		BOOL limitPref = GrowlBrushedLimitPrefDefault;
		if([self.configurationDict valueForKey:GrowlBrushedLimitPref]){
			limitPref = [[self.configurationDict valueForKey:GrowlBrushedLimitPref] boolValue];
		}
		containerSize.width = GrowlBrushedTextAreaWidth;
		if (limitPref)
			containerSize.height = lineHeight * GrowlBrushedMaxLines;
		else
			containerSize.height = FLT_MAX;
		textStorage = [[NSTextStorage alloc] init];
		textContainer = [[NSTextContainer alloc] initWithContainerSize:containerSize];
		[textLayoutManager addTextContainer:textContainer];	// retains textContainer
		[textStorage addLayoutManager:textLayoutManager];	// retains layoutManager
		textContainer.lineFragmentPadding = 0.0;
	}
    
	// construct attributes for the description text
	NSDictionary *defaultAttributes = @{NSFontAttributeName: textFont,
                                       NSForegroundColorAttributeName: textColor,
                                       NSShadowAttributeName: textShadow};
    
	[textStorage.mutableString setString:aText];
	[textStorage setAttributes:defaultAttributes range:NSMakeRange(0, textStorage.length)];
    
    
	textRange = [textLayoutManager glyphRangeForTextContainer:textContainer];	// force layout
	textHeight = [textLayoutManager usedRectForTextContainer:textContainer].size.height;
    
	[self setNeedsDisplay:YES];
}

- (void) setPriority:(int)priority {
	NSString *textKey;
	switch (priority) {
		case -2:
			textKey = GrowlBrushedVeryLowTextColor;
			break;
		case -1:
			textKey = GrowlBrushedModerateTextColor;
			break;
		case 1:
			textKey = GrowlBrushedHighTextColor;
			break;
		case 2:
			textKey = GrowlBrushedEmergencyTextColor;
			break;
		case 0:
		default:
			textKey = GrowlBrushedNormalTextColor;
			break;
	}
	NSData *data = [self.configurationDict valueForKey:textKey];
	
	if (data && [data isKindOfClass:[NSData class]]) {
		textColor = [NSUnarchiver unarchiveObjectWithData:data];
	} else {
		textColor = [NSColor colorWithCalibratedWhite:0.1f alpha:1.0f];
	}
	data = nil;
}

- (void) sizeToFit {
	CGFloat height = GrowlBrushedPadding + GrowlBrushedPadding + self.titleHeight + self.descriptionHeight;
	if (haveTitle && haveText)
		height += GrowlBrushedTitleTextPadding;
	if (height < GrowlBrushedMinTextHeight)
		height = GrowlBrushedMinTextHeight;
    
	// resize the window so that it contains the tracking rect
	NSWindow *window = self.window;
	NSRect windowRect = self.window.frame;
	windowRect.origin.y -= height - windowRect.size.height;
	windowRect.size.height = height;
	[window setFrame:windowRect display:YES animate:YES];
    
	if (trackingRectTag)
		[self removeTrackingRect:trackingRectTag];
	trackingRectTag = [self addTrackingRect:self.frame owner:self userData:NULL assumeInside:NO];
}

- (CGFloat) titleHeight {
	return haveTitle ? titleHeight : 0.0;
}

- (CGFloat) descriptionHeight {
	return haveText ? textHeight : 0.0;
}

- (NSInteger) descriptionRowCount {
	NSInteger rowCount = textHeight / lineHeight;
	BOOL limitPref = GrowlBrushedLimitPrefDefault;
	if([self.configurationDict valueForKey:GrowlBrushedLimitPref]){
		limitPref = [[self.configurationDict valueForKey:GrowlBrushedLimitPref] boolValue];
	}
	if (limitPref)
		return MIN(rowCount, GrowlBrushedMaxLines);
	else
		return rowCount;
}

@end
