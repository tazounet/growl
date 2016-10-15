//
//  GrowlMistView.m
//
//  Created by Rachel Blackman on 7/11/11.
//

#import "GrowlMistView.h"
#import "NSImageAdditions.h"

@implementation GrowlMistView

@synthesize notificationText;
@synthesize notificationTitle;
@synthesize notificationImage;
@synthesize delegate;

- (instancetype)initWithFrame:(NSRect)frame {
   self = [super initWithFrame:frame];
   if (self) {
      clipPath = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:8 yRadius:8];
      NSRect insetRect = NSInsetRect(self.bounds, 1, 1);
      strokePath = [NSBezierPath bezierPathWithRoundedRect:insetRect xRadius:8 yRadius:8];
      NSMutableParagraphStyle *titleParaStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:nil];
      titleParaStyle.lineBreakMode = NSLineBreakByTruncatingTail;
      notificationTitleFont = [NSFont boldSystemFontOfSize:MIST_TITLE_SIZE];
      notificationTitleAttrs = @{NSFontAttributeName: notificationTitleFont,NSForegroundColorAttributeName: [NSColor whiteColor],NSParagraphStyleAttributeName: titleParaStyle};
      notificationTextFont = [NSFont systemFontOfSize:MIST_TEXT_SIZE];
      notificationTextAttrs = @{NSFontAttributeName: notificationTextFont,NSForegroundColorAttributeName: [NSColor whiteColor]};
      
      trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:nil];
      [self addTrackingArea:trackingArea];
   }
   return self;
}

- (void)dealloc {
   [self removeTrackingArea:trackingArea];
}

// Override the default synthesized notificationImage setter, to pre-size our image.
- (void)setNotificationImage:(NSImage *)image {
   notificationImage = [[image imageSizedToDimensionSquaring:MIST_IMAGE_DIM] flippedImage];
}

- (void)setFrame:(NSRect)frameRect
{
   super.frame = frameRect;
   
   clipPath = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:8 yRadius:8];
   
   NSRect insetRect = NSInsetRect(self.bounds, 1, 1);
   strokePath = [NSBezierPath bezierPathWithRoundedRect:insetRect xRadius:8 yRadius:8];
   
   [self removeTrackingArea:trackingArea];
   trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:nil];
   [self addTrackingArea:trackingArea];
}

- (BOOL)isOpaque {
   return NO;
}

- (BOOL)isFlipped {
   return YES;
}

- (void)sizeToFit {
   NSRect imageRect = NSZeroRect;
   if (notificationImage) {
      imageRect.size = notificationImage.size;
   }
   
   NSRect titleRect = NSZeroRect;
   if (notificationTitle) {
      NSSize titleSize = [notificationTitle sizeWithAttributes:notificationTitleAttrs];
      titleRect.size = titleSize;
   }
   
   CGFloat baseWidth = imageRect.size.width + (MIST_TEXT_PADDING * 2);
   
    NSRect textRect = CGRectZero;
    if(notificationText != nil)
        textRect = [notificationText boundingRectWithSize:NSMakeSize((CGFloat)(MIST_WIDTH - baseWidth), (CGFloat)(1e7)) options:(NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin) attributes:notificationTextAttrs];
   
   NSRect myFrame = self.frame;
   myFrame.size.width = MIST_WIDTH;
   myFrame.size.height = titleRect.size.height + textRect.size.height + (notificationTitle ? MIST_TEXT_LINESPACE * 2 : 0) + (MIST_PADDING * 2);
   
   if (myFrame.size.height < (MIST_IMAGE_DIM + (MIST_PADDING * 2)))
      myFrame.size.height = MIST_IMAGE_DIM + (MIST_PADDING * 2);
   
   self.frame = myFrame;
}

- (void)drawRect:(NSRect)rect {
   [[NSGraphicsContext currentContext] saveGraphicsState];
   
   if (selected) {
      [[NSColor colorWithDeviceWhite:0.0f alpha:1.0f] set];
   }
   else {
      [[NSColor colorWithDeviceWhite:0.0f alpha:0.75f] set];
   }
   [clipPath fill];
   
   if (selected) {
      [[NSColor whiteColor] set];
      strokePath.lineWidth = 3.0f;
      [strokePath stroke];
   }
   
   // Draw image.
   NSRect imageRect = NSZeroRect;
   if (notificationImage) {
      imageRect.size = notificationImage.size;
      imageRect.origin.x = self.bounds.origin.x + MIST_PADDING;
      imageRect.origin.y = self.bounds.origin.y + MIST_PADDING;
      [notificationImage drawInRect:imageRect];
   }
   
   // Draw title.
   NSRect titleRect = NSZeroRect;
   if (notificationTitle) {
      NSSize titleSize = [notificationTitle sizeWithAttributes:notificationTitleAttrs];
      titleRect.size = titleSize;
      titleRect.origin.y = self.bounds.origin.y + MIST_PADDING;
      titleRect.origin.x = imageRect.origin.x + imageRect.size.width + MIST_TEXT_PADDING;
      
      [notificationTitle drawInRect:titleRect withAttributes:notificationTitleAttrs];
   }
   
   // Draw text.
   if (notificationText) {
      CGFloat baseWidth = imageRect.size.width + (MIST_TEXT_PADDING * 2);
      
      NSRect textRect = [notificationText boundingRectWithSize:NSMakeSize((CGFloat)(MIST_WIDTH - baseWidth), (CGFloat)1e7) options:(NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin) attributes:notificationTextAttrs];
      textRect.origin.x = imageRect.origin.x + imageRect.size.width + MIST_TEXT_PADDING;
      textRect.origin.y = titleRect.origin.y + titleRect.size.height + (notificationTitle ? MIST_TEXT_LINESPACE * 2 : MIST_PADDING);
      
      [notificationText drawInRect:textRect withAttributes:notificationTextAttrs];
   }
   
   if (selected) {
      // Draw mouseover close button
   }
   
   [[NSGraphicsContext currentContext] restoreGraphicsState];
   
}

- (void)mouseEntered:(NSEvent *)theEvent {
   selected = YES;
   [self setNeedsDisplay:YES];
   if ([self.delegate respondsToSelector:@selector(mistViewSelected:)])
      [self.delegate mistViewSelected:YES];
}

- (void)mouseExited:(NSEvent *)theEvent {
   selected = NO;
   [self setNeedsDisplay:YES];
   if ([self.delegate respondsToSelector:@selector(mistViewSelected:)])
      [self.delegate mistViewSelected:NO];
}

- (void)mouseDown:(NSEvent *)theEvent {
   if((theEvent.modifierFlags & NSEventModifierFlagOption) != 0){
      if([self.delegate respondsToSelector:@selector(closeAllNotifications)])
         [self.delegate closeAllNotifications];
   }else{
      if ([self.delegate respondsToSelector:@selector(mistViewDismissed:)])
         [self.delegate mistViewDismissed:NO];
   }
}

@end
