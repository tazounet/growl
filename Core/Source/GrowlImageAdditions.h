//
//  GrowlImageAdditions.h
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 20/09/04.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Cocoa/Cocoa.h>
#import "GrowlDefinesInternal.h"	// for CGFloat

@interface NSImage (GrowlImageAdditions)

- (void) drawScaledInRect:(NSRect)targetRect operation:(NSCompositingOperation)operation fraction:(CGFloat)f neverFlipped:(BOOL)neverFlipped;
- (NSSize) adjustSizeToDrawAtSize:(NSSize)theSize;
- (NSImageRep *) bestRepresentationForSize:(NSSize)theSize;
- (NSImageRep *) representationOfSize:(NSSize)theSize;
- (NSData *) PNGRepresentation;

// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Works like |-drawInRect:fromRect:operation:fraction:|, except that
// if |neverFlipped| is |YES|, and the context is flipped, the a
// transform is applied to flip it again before drawing the image.
//
// Compare to the 10.6 method
// |-drawInRect:fromRect:operation:fraction:respectFlipped:hints:|.
- (void) drawInRect:(NSRect)dstRect
         fromRect:(NSRect)srcRect
         operation:(NSCompositingOperation)op
         fraction:(CGFloat)requestedAlpha
         neverFlipped:(BOOL)neverFlipped;

@end
