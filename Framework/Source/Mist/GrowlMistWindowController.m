//
//  GrowlMistWindowController.m
//
//  Created by Rachel Blackman on 7/13/11.
//

#import "GrowlMistWindowController.h"

#import "GrowlDefinesInternal.h"

@interface GrowlMistWindowController ()

@property (nonatomic,assign) BOOL sticky;
@property (nonatomic,assign) BOOL visible;
@property (nonatomic,assign) BOOL selected;
@property (nonatomic,retain) NSString *uuid;

@end

@implementation GrowlMistWindowController
@synthesize fadeAnimation;
@synthesize lifetime;
@synthesize sticky;
@synthesize uuid;
@synthesize visible;
@synthesize delegate;
@synthesize selected;

- (instancetype)initWithNotificationTitle:(NSString *)title
                                     text:(NSString *)text
                                    image:(NSImage *)image
                                   sticky:(BOOL)isSticky
                                     uuid:(id)theUUID
                                 delegate:(id)aDelegate
{
   GrowlMistView *mistViewForSetup = [[GrowlMistView alloc] initWithFrame:NSZeroRect];
   mistViewForSetup.notificationTitle = title;
   mistViewForSetup.notificationText = text;
   mistViewForSetup.notificationImage = image;
   mistViewForSetup.delegate = self;
   [mistViewForSetup sizeToFit];
   
   NSRect mistRect = mistViewForSetup.frame;
   NSPanel *tempWindow = [[NSPanel alloc] initWithContentRect:mistRect
                                                    styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel
                                                      backing:NSBackingStoreBuffered
                                                        defer:YES];
   
   self = [super initWithWindow:tempWindow];
   if (self) {
      mistView = mistViewForSetup;
      [tempWindow setBecomesKeyOnlyIfNeeded:YES];
      [tempWindow setHidesOnDeactivate:NO];
      [tempWindow setCanHide:NO];
      tempWindow.contentView = mistView;
      [tempWindow setOpaque:NO];
      tempWindow.backgroundColor = [NSColor clearColor];
      [tempWindow setLevel:GrowlVisualDisplayWindowLevel];
      //We won't have this on 10.6, define it so we don't have issues on 10.6
#define NSWindowCollectionBehaviorFullScreenAuxiliary 1 << 8
      tempWindow.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces|NSWindowCollectionBehaviorFullScreenAuxiliary;
      [tempWindow setAcceptsMouseMovedEvents:YES];
      [tempWindow setOneShot:YES];
      self.uuid = theUUID;
      self.delegate = aDelegate;
      self.visible = NO;
      self.sticky = isSticky;
      if (!sticky)
         self.lifetime = [NSTimer scheduledTimerWithTimeInterval:MIST_LIFETIME
                                                          target:self
                                                        selector:@selector(lifetimeExpired:)
                                                        userInfo:nil
                                                         repeats:NO];
   }
   return self;
}

- (void)dealloc {
   delegate = nil;
   [lifetime invalidate];
   lifetime = nil;
   fadeAnimation.delegate = nil;
   [fadeAnimation stopAnimation];
   fadeAnimation = nil;
   mistView.delegate = nil;
   mistView = nil;
}

- (void)setLifetime:(NSTimer *)aLifetime
{
   [lifetime invalidate];
   lifetime = aLifetime;
}

- (void)setFadeAnimation:(NSViewAnimation *)aFadeAnimation
{
   fadeAnimation.delegate = nil;
   [fadeAnimation stopAnimation];
   fadeAnimation = aFadeAnimation;
}

- (void)fadeIn {
   self.window.alphaValue = 0.0f;
   [self.window orderFront:nil];
   
   NSDictionary *fadeIn = @{NSViewAnimationTargetKey: self.window,
                           NSViewAnimationEffectKey: NSViewAnimationFadeInEffect};
   
   NSArray *animations;
   animations = @[fadeIn];
   
   self.fadeAnimation = [[NSViewAnimation alloc]
                            initWithViewAnimations:animations];
   
   (self.fadeAnimation).animationBlockingMode = NSAnimationNonblocking;
   (self.fadeAnimation).duration = 0.3;
   [self.fadeAnimation startAnimation];
   visible = YES;
}

- (void)animationDidEnd:(NSAnimation *)animation {
   [self.window orderOut:nil];
   visible = NO;
   
   // Callback to our delegate, to let it know that we've finished.
   if (closed) {
      // We were closed via timeout or the close button
      if ([self.delegate respondsToSelector:@selector(mistNotificationDismissed:)])
         [self.delegate mistNotificationDismissed:self];
   }
   else {
      // We were clicked properly and so should use the callback
      if ([self.delegate respondsToSelector:@selector(mistNotificationClicked:)])
         [self.delegate mistNotificationClicked:self];
   }
}

- (void)animationDidStop:(NSAnimation *)animation {
   [self animationDidEnd:animation];
}

- (void)fadeOut {
   NSDictionary *fadeOut = @{NSViewAnimationTargetKey: self.window,
                            NSViewAnimationEffectKey: NSViewAnimationFadeOutEffect};
   
   NSArray *animations;
   animations = @[fadeOut];
   
   self.fadeAnimation = [[NSViewAnimation alloc]
                            initWithViewAnimations:animations];
   
   (self.fadeAnimation).animationBlockingMode = NSAnimationNonblocking;
   (self.fadeAnimation).duration = 0.3;
   (self.fadeAnimation).delegate = self;
   [self.fadeAnimation startAnimation];
}

- (void)mistViewDismissed:(BOOL)wasClosed
{
   closed = wasClosed;
   [self fadeOut];
}


- (void)lifetimeExpired:(NSNotification *)timerNotification {
   // Act like the close button was clicked.
   [self mistViewDismissed:YES];
}

- (void)mistViewSelected:(BOOL)isSelected
{
   selected = isSelected;
   // Stop our lifetime-timer
   if (selected) {
      self.lifetime = nil;
   }
   else {
      if (!sticky) {
         self.lifetime = [NSTimer scheduledTimerWithTimeInterval:MIST_LIFETIME target:self selector:@selector(lifetimeExpired:) userInfo:nil repeats:NO];
      }
   }
}

- (void)closeAllNotifications
{
   if([self.delegate respondsToSelector:@selector(closeAllNotifications:)])
      [self.delegate closeAllNotifications:self];
}

@end
