//
//  NSImageAdditions.h
//
//  Created by Rachel Blackman on 7/13/11.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (GrowlAdditions)

#if __MAC_OS_X_VERSION_MAX_ALLOWED < 1090
- (void) drawInRect:(NSRect)rect;
#endif

- (NSImage *) flippedImage;
- (NSImage *) imageSizedToDimension:(int)dimension;
- (NSImage *) imageSizedToDimensionScalingUp:(int)dimension;
- (NSImage *) imageSizedToDimensionSquaring:(int)dimension;


@end
