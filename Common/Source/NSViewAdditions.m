//
//  NSViewAdditions.m
//  Growl
//
//  Created by Peter Hosey on 2005-06-26
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "NSViewAdditions.h"

@implementation NSView (GrowlAdditions)

- (NSData *) dataWithPNGInsideRect:(NSRect)rect {
	[self lockFocus];
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:rect];
	[self unlockFocus];

	NSData *data = [bitmap representationUsingType:NSPNGFileType
	                                    properties:nil];

	return data;
}

- (NSPoint)convertPointFromScreen:(NSPoint)point
{
    // -[NSWindow convertScreenToBase:] is deprecated, so we have to work with an NSRect
    NSRect screenRect = (NSRect){.origin = point, .size = NSMakeSize(0.0f, 0.0f)};
    NSPoint windowPoint = [[self window] convertRectFromScreen:screenRect].origin;
    return [self convertPoint:windowPoint fromView:nil];
}

- (NSPoint)convertPointToScreen:(NSPoint)point
{
    // -[NSWindow convertBaseToScreen:] is deprecated, so we have to work with an NSRect
    NSPoint windowPoint = [self convertPoint:point toView:nil];
    NSRect windowRect = (NSRect){.origin = windowPoint, .size = NSMakeSize(0.0f, 0.0f)};
    return [[self window] convertRectToScreen:windowRect].origin;
}

@end
