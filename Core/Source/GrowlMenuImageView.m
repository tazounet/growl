//
//  GrowlMenuImageView.m
//  Growl
//
//  Created by Daniel Siemer on 10/10/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlMenuImageView.h"
#import "GrowlMenu.h"
#import <QuartzCore/QuartzCore.h>

@implementation GrowlMenuImageView

@synthesize mode;

@synthesize menuItem;
@synthesize mainImage;
@synthesize alternateImage;
@synthesize squelchImage;
@synthesize mouseDown;
@synthesize darkModeOn;
@synthesize isHighlighted;

static NSImageView *imageView;

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        // Initialization code here.
        menuItem = nil;
        mainImage = nil;
        alternateImage = nil;
        squelchImage = nil;
        mouseDown = NO;
        mode = 0;

        imageView = [[NSImageView alloc] initWithFrame:self.bounds];
        imageView.wantsLayer = YES;
        [self addSubview:imageView];

        self.toolTip = @"Growl";

        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(darkModeChanged:) name:@"AppleInterfaceThemeChangedNotification" object:nil];
        [self updateDarkMode];
    }
    
    return self;
}

- (void)setMenuItem:(GrowlMenu*)newMenuItem
{
    menuItem = newMenuItem;
    [menuItem.menu setDelegate:self];
}

-(void)updateDarkMode
{
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain];
    id style = dict[@"AppleInterfaceStyle"];
    
    darkModeOn = (style && [style isKindOfClass:[NSString class]] && NSOrderedSame == [style caseInsensitiveCompare:@"dark"]);
}

-(void)darkModeChanged:(NSNotification *)notif
{
    [self updateDarkMode];

    if(darkModeOn) {
        [self setIcon:alternateImage];
    } else {
        [self setIcon:mainImage];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    [menuItem.statusItem drawStatusBarBackgroundInRect:dirtyRect withHighlight:self.isHighlighted];

    switch(mode)
    {
        case 1:
            [self setIcon:alternateImage];
            break;
        case 2:
            previousMode = self.mode;
            [self setIcon:squelchImage];
            break;
        case 0:
        default:
            previousMode = self.mode;
            if(darkModeOn) {
                [self setIcon:alternateImage];
            } else {
                [self setIcon:mainImage];
            }
            break;
    }
}

- (void)setIcon:(NSImage *)icon
{
    [imageView setImage:icon];
}

- (void)startAnimation
{
    if(![imageView.layer animationForKey:@"pulseAnimation"])
    {
        CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"opacity"];
        anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        anim.duration = 1.0f;
        anim.repeatCount = HUGE_VALF;
        anim.autoreverses = YES;
        anim.removedOnCompletion = NO;
        anim.toValue = @0.0f;
        [imageView.layer addAnimation:anim forKey:@"pulseAnimation"];
    }
}

- (void)stopAnimation
{
    [imageView.layer removeAnimationForKey:@"pulseAnimation"];
}

-(void)mouseDown:(NSEvent *)theEvent
{
    self.mouseDown = YES;
    [menuItem.statusItem popUpStatusItemMenu:menuItem.menu];
    self.mouseDown = NO;
}

-(void)menuWillOpen:(NSMenu *)menu {
    self.mode = 1;
    self.isHighlighted = YES;
    self.needsDisplay = YES;
}

-(void)menuDidClose:(NSMenu *)menu {
    self.mode = previousMode;
    self.isHighlighted = NO;
    self.needsDisplay = YES;
}

- (void)setHighlighted:(BOOL)newFlag
{
    if (isHighlighted == newFlag) return;
    isHighlighted = newFlag;
    self.needsDisplay = YES;
}

@end
