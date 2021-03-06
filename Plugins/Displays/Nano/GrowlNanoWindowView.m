//
//  GrowlNanoWindowView.m
//  Display Plugins
//
//  Created by Rudy Richter on 12/12/2005.
//  Copyright 2005–2011, The Growl Project. All rights reserved.
//

#import "GrowlNanoWindowView.h"
#import "GrowlNanoPrefs.h"
#import "GrowlImageAdditions.h"

extern CGLayerRef CGLayerCreateWithContext() __attribute__((weak_import));

void addRoundedBottomToPath(CGContextRef context, CGRect rect, CGFloat radius);


void addRoundedBottomToPath(CGContextRef context, CGRect rect, CGFloat radius) {
	CGFloat minX = CGRectGetMinX(rect);
	CGFloat minY = CGRectGetMinY(rect);
	CGFloat maxX = CGRectGetMaxX(rect);
	CGFloat maxY = CGRectGetMaxY(rect);
	CGFloat midX = CGRectGetMidX(rect);
	CGFloat midY = CGRectGetMidY(rect);

	CGContextBeginPath(context);
	CGContextMoveToPoint(context, maxX, midY);
	CGContextAddLineToPoint(context, maxX, maxY);
	CGContextAddLineToPoint(context, minX, maxY);
	CGContextAddLineToPoint(context, minX, midY);
	CGContextAddArcToPoint(context, minX, minY, midX, minY, radius);
	CGContextAddArcToPoint(context, maxX, minY, maxX, midY, radius);
	CGContextClosePath(context);
}

@implementation GrowlNanoWindowView

- (instancetype) initWithFrame:(NSRect)frame {
	if ((self = [super initWithFrame:frame])) {
		cache = [[NSImage alloc] initWithSize:frame.size];
		needsDisplay = YES;
	}

	return self;
}

- (void) dealloc {
	if (layer)
		CGLayerRelease(layer);

}

- (void) drawRect:(NSRect)rect {
		
	NSGraphicsContext *context = [NSGraphicsContext currentContext];
	CGContextRef cgContext = context.graphicsPort;
	NSRect bounds = self.bounds;

	if (needsDisplay) {
		// rects and sizes
		int sizePref = 0;
		if([self.configurationDict valueForKey:Nano_SIZE_PREF]){
			sizePref = [[self.configurationDict valueForKey:Nano_SIZE_PREF] intValue];
		}
		NSRect titleRect, textRect;
		NSRect iconRect;

		if (sizePref == Nano_SIZE_HUGE) {
			titleRect.origin.x = 10.0;
			titleRect.origin.y = NSHeight(bounds) - 28.0;
			titleRect.size.width = NSWidth(bounds) - 32.0;
			titleRect.size.height = 20.0;
			
			textRect.origin.y = NSHeight(bounds) - 41.0;
			textRect.size.height = 15.0;
			
			iconRect.origin.x = 230.0;
			iconRect.origin.y = NSHeight(bounds) - 40.0;
			iconRect.size.width = 32.0;
			iconRect.size.height = 32.0;
		} else {
			titleRect.origin.x = 10.0;
			titleRect.origin.y = NSHeight(bounds) - 14.0;
			titleRect.size.width = NSWidth(bounds) - 16.0;
			titleRect.size.height = 12.0;
			
			textRect.origin.y = NSHeight(bounds) - 22.0;
			textRect.size.height = 10.0;
			
			iconRect.origin.x = 160.0;
			iconRect.origin.y = NSHeight(bounds) - 20.0;
			iconRect.size.width = 16.0;
			iconRect.size.height = 16.0;
		}
		textRect.origin.x = titleRect.origin.x;
		textRect.size.width = titleRect.size.width;

		//draw to cache
		/*if (CGLayerCreateWithContext) {
			if (!layer)
				layer = CGLayerCreateWithContext(cgContext, CGSizeMake(bounds.size.width, bounds.size.height), NULL);
			[NSGraphicsContext setCurrentContext:
				[NSGraphicsContext graphicsContextWithGraphicsPort:CGLayerGetContext(layer) flipped:NO]];
		} else {
			[cache lockFocus];
		}*/

		NSRect c = self.bounds;
		CGRect b = CGRectMake(c.origin.x, c.origin.y, c.size.width, c.size.height);
		addRoundedBottomToPath(cgContext, b, 10.0);

		CGFloat opacityPref = Nano_DEFAULT_OPACITY;
		if([self.configurationDict valueForKey:Nano_OPACITY_PREF]){
			opacityPref = [[self.configurationDict valueForKey:Nano_OPACITY_PREF] floatValue];
		}
		CGFloat alpha = opacityPref * 0.01;
		[[backgroundColor colorWithAlphaComponent:alpha] set];
		CGContextFillPath(cgContext);

		////NSRectFill(bounds);
		[title drawInRect:titleRect withAttributes:titleAttributes];

		[text drawInRect:textRect withAttributes:textAttributes];
		[icon drawScaledInRect:iconRect operation:NSCompositingOperationSourceOver fraction:1.0 neverFlipped:NO];

		/*if (CGLayerCreateWithContext)
			[NSGraphicsContext setCurrentContext:context];
		else
			[cache unlockFocus];

		needsDisplay = NO;*/
	}

	// draw background
	//[[NSColor clearColor] set];
	//NSRectFill(rect);
	//CGContextFillPath(cgContext);
	// draw cache to screen
	NSRect imageRect = rect;
	int effect = Nano_EFFECT_SLIDE;
	if([self.configurationDict valueForKey:Nano_EFFECT_PREF]){
		effect = [[self.configurationDict valueForKey:Nano_EFFECT_PREF] intValue];
	}
	if (effect == Nano_EFFECT_SLIDE) {
		if (CGLayerCreateWithContext)
			imageRect.origin.y = 0.0;
	} else if (effect == Nano_EFFECT_WIPE) {
		rect.size.height -= imageRect.origin.y;
		imageRect.size.height -= imageRect.origin.y;
		if (!CGLayerCreateWithContext)
			imageRect.origin.y = 0.0;
	}

	if (CGLayerCreateWithContext) {
		CGRect cgRect;
		cgRect.origin.x = imageRect.origin.x;
		cgRect.origin.y = imageRect.origin.y;
		cgRect.size.width = rect.size.width;
		if (effect == Nano_EFFECT_WIPE) {
			cgRect.size.height = rect.size.height;
			CGContextClipToRect(cgContext, cgRect);
		}
		cgRect.size.height = bounds.size.height;
		CGContextDrawLayerInRect(cgContext, cgRect, layer);
	} else {
		[cache drawInRect:rect fromRect:imageRect operation:NSCompositingOperationSourceOver fraction:1.0];
	}
}

- (void) setIcon:(NSImage *)anIcon {
	icon = anIcon;
	self.needsDisplay = (needsDisplay = YES);
}

- (void) setTitle:(NSString *)aTitle {
	title = [aTitle copy];
	self.needsDisplay = (needsDisplay = YES);
}

- (void) setText:(NSString *)aText {
	text = [aText copy];
	self.needsDisplay = (needsDisplay = YES);
}

- (void) setPriority:(int)priority {
	NSString *key;
	NSString *textKey;
	switch (priority) {
		case -2:
			key = GrowlNanoVeryLowBackgroundColor;
			textKey = GrowlNanoVeryLowTextColor;
			break;
		case -1:
			key = GrowlNanoModerateBackgroundColor;
			textKey = GrowlNanoModerateTextColor;
			break;
		case 1:
			key = GrowlNanoHighBackgroundColor;
			textKey = GrowlNanoHighTextColor;
			break;
		case 2:
			key = GrowlNanoEmergencyBackgroundColor;
			textKey = GrowlNanoEmergencyTextColor;
			break;
		case 0:
		default:
			key = GrowlNanoNormalBackgroundColor;
			textKey = GrowlNanoNormalTextColor;
			break;
	}


	CGFloat opacityPref = Nano_DEFAULT_OPACITY;
	if([self.configurationDict valueForKey:Nano_OPACITY_PREF]){
		opacityPref = [[self.configurationDict valueForKey:Nano_OPACITY_PREF] floatValue];
	}
	CGFloat alpha = opacityPref * 0.01;

	Class NSDataClass = [NSData class];
	NSData *data = [self.configurationDict valueForKey:key];

	if (data && [data isKindOfClass:NSDataClass])
		backgroundColor = [NSUnarchiver unarchiveObjectWithData:data];
	else
		backgroundColor = [NSColor blackColor];
	backgroundColor = [backgroundColor colorWithAlphaComponent:alpha];

	data = nil;
	data = [self.configurationDict valueForKey:textKey];
	if (data && [data isKindOfClass:NSDataClass])
		textColor = [NSUnarchiver unarchiveObjectWithData:data];
	else
		textColor = [NSColor whiteColor];

	CGFloat titleFontSize;
	CGFloat textFontSize;
	int sizePref = 0;
	if([self.configurationDict valueForKey:Nano_SIZE_PREF]){
		sizePref = [[self.configurationDict valueForKey:Nano_SIZE_PREF] intValue];
	}

	if (sizePref == Nano_SIZE_HUGE) {
		titleFontSize = 14.0;
		textFontSize = 12.0;
	} else {
		titleFontSize = 10.0;
		textFontSize = 8.0;
	}

	NSShadow *textShadow = [[NSShadow alloc] init];

	NSSize shadowSize = {0.0, -2.0};
	textShadow.shadowOffset = shadowSize;
	textShadow.shadowBlurRadius = 3.0;
	textShadow.shadowColor = [NSColor blackColor];

	NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	paragraphStyle.alignment = NSTextAlignmentLeft;
	paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
	titleAttributes = @{NSForegroundColorAttributeName: textColor,
		NSParagraphStyleAttributeName: paragraphStyle,
		NSFontAttributeName: [NSFont boldSystemFontOfSize:titleFontSize],
		NSShadowAttributeName: textShadow};

	paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	paragraphStyle.alignment = NSTextAlignmentLeft;
	textAttributes = @{NSForegroundColorAttributeName: textColor,
		NSParagraphStyleAttributeName: paragraphStyle,
		NSFontAttributeName: [NSFont messageFontOfSize:textFontSize],
		NSShadowAttributeName: textShadow};
}

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

#pragma mark -

- (BOOL) needsDisplay {
	return needsDisplay && super.needsDisplay;
}

@end
