//
//  GrowlBrushedWindowView.h
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004–2011 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <GrowlPlugins/GrowlNotificationView.h>

@interface GrowlBrushedWindowView : GrowlNotificationView {
	BOOL				haveTitle;
	BOOL				haveText;
	NSImage				*icon;
	CGFloat				iconSize;
	CGFloat				textHeight;
	CGFloat				titleHeight;
	CGFloat				lineHeight;

	NSFont				*textFont;
	NSShadow			*textShadow;
	NSColor				*textColor;

	NSLayoutManager		*textLayoutManager;
	NSTextStorage		*textStorage;
	NSTextContainer		*textContainer;
	NSRange				textRange;

	NSLayoutManager		*titleLayoutManager;
	NSTextStorage		*titleStorage;
	NSTextContainer		*titleContainer;
	NSRange				titleRange;
}

- (instancetype)initWithFrame:(NSRect)frameRect NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

- (instancetype) initWithFrame:(NSRect)frameRect configurationDict:(NSDictionary*)configDict NS_DESIGNATED_INITIALIZER;

- (void) setIcon:(NSImage *)icon;
- (void) setTitle:(NSString *)title;
- (void) setText:(NSString *)text;

- (void) setPriority:(int)priority;

- (void) sizeToFit;
- (CGFloat) titleHeight;
- (CGFloat) descriptionHeight;
- (NSInteger) descriptionRowCount;
@end
