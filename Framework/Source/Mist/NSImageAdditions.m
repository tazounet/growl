//
//  NSImageAdditions.m
//
//  Created by Rachel Blackman on 7/13/11.
//

#import "NSImageAdditions.h"


@implementation NSImage (GrowlAdditions)

- (NSImage *) flippedImage
{
    NSImage *l_result = [[NSImage alloc] initWithSize:self.size];
    [l_result lockFocus];
    [NSGraphicsContext currentContext].imageInterpolation = NSImageInterpolationNone;
    [[NSGraphicsContext currentContext] setShouldAntialias:NO];
    NSRect l_target = NSZeroRect;
    l_target.size = self.size;
	
    NSAffineTransform* xform = [NSAffineTransform transform];
    [xform translateXBy:0.0f yBy:l_target.size.height];
    [xform scaleXBy:1.0f yBy:-1.0f];
    [xform concat];    
    
    [self drawInRect:l_target fromRect:l_target operation:NSCompositingOperationCopy fraction:1.0f];
    [l_result unlockFocus];
    
    return l_result;
}

- (NSImage *) imageSizedToDimension:(int)dimension
{
	NSSize imageSize = self.size;
	
	if ((imageSize.width <= dimension) && (imageSize.height <= dimension))
		return self;
	
	return [self imageSizedToDimensionScalingUp:dimension];
}

- (NSImage *) imageSizedToDimensionScalingUp:(int)dimension
{
	NSSize imageSize = self.size;
	double ratio = 1;
	
	if (imageSize.width > imageSize.height) {
		ratio = imageSize.height / imageSize.width;
		imageSize.width = dimension;
		imageSize.height = (CGFloat)(dimension * ratio);
	}
	else {
		ratio = imageSize.width / imageSize.height;
		imageSize.height = dimension;
		imageSize.width = (CGFloat)(dimension * ratio);				
	}
	
	NSImage *result = [[NSImage alloc] initWithSize:imageSize];
	[result lockFocus];
	[NSGraphicsContext currentContext].imageInterpolation = NSImageInterpolationHigh;
	
	NSRect destRect = NSZeroRect;
	destRect.size = imageSize;
	NSRect sourceRect = NSZeroRect;
	sourceRect.size = self.size;
	
	[self drawInRect:destRect fromRect:sourceRect operation:NSCompositingOperationCopy fraction:1.0f];
	
	[result unlockFocus];
	
	return result;
}

- (NSImage *) imageSizedToDimensionSquaring:(int)dimension
{
	NSSize imageSize = self.size;
	double ratio = 1;
	
	if (imageSize.width > imageSize.height) {
		ratio = imageSize.height / imageSize.width;
		imageSize.width = dimension;
		imageSize.height = (CGFloat)(dimension * ratio);
	}
	else {
		ratio = imageSize.width / imageSize.height;
		imageSize.height = dimension;
		imageSize.width = (CGFloat)(dimension * ratio);				
	}
	
	NSSize finalSize = NSMakeSize(dimension, dimension);
	
	NSImage *result = [[NSImage alloc] initWithSize:finalSize];
	[result lockFocus];
	[NSGraphicsContext currentContext].imageInterpolation = NSImageInterpolationHigh;
	
	NSRect destRect = NSZeroRect;
	destRect.size = imageSize;
	
	destRect.origin.y = truncf((float)(dimension - destRect.size.height) / 2);
	destRect.origin.x = truncf((float)(dimension - destRect.size.width) / 2);
	
	NSRect sourceRect = NSZeroRect;
	sourceRect.size = self.size;
	
	[self drawInRect:destRect fromRect:sourceRect operation:NSCompositingOperationCopy fraction:1.0f];
	
	[result unlockFocus];
	
	return result;
}

#if __MAC_OS_X_VERSION_MAX_ALLOWED < 1090
- (void) drawInRect:(NSRect)rect
{
	NSRect sourceRect = NSZeroRect;
	sourceRect.size = [self size];
	[self drawInRect:rect fromRect:sourceRect operation:NSCompositeSourceOver fraction:1.0f];
}
#endif

@end
