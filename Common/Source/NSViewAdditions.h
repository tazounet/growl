//
//  NSViewAdditions.h
//  Growl
//
//  Created by Peter Hosey on 2005-06-26
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Cocoa/Cocoa.h>

@interface NSView (GrowlAdditions)

- (NSData *) dataWithPNGInsideRect:(NSRect)rect;

// Copyright 1997-2013 Omni Development, Inc. All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

- (NSPoint)convertPointFromScreen:(NSPoint)point;
- (NSPoint)convertPointToScreen:(NSPoint)point;

@end
