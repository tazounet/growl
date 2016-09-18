//
//  GrowlMenuImageView.h
//  Growl
//
//  Created by Daniel Siemer on 10/10/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import <AppKit/AppKit.h>

@class GrowlMenu;

@interface GrowlMenuImageView : NSView <CALayerDelegate> {
   GrowlMenu *__weak menuItem;
   
    NSInteger mode;
    NSInteger previousMode;
    CALayer *mainLayer;
    NSImage *mainImage;
    NSImage *alternateImage;
    NSImage *squelchImage;
    
    BOOL mouseDown;
    BOOL darkModeOn;
}

@property (nonatomic, assign) NSInteger mode;
@property (nonatomic, weak) GrowlMenu* menuItem;
@property (nonatomic, strong) CALayer *mainLayer;
@property (nonatomic, assign) BOOL mouseDown;
@property (nonatomic, assign) BOOL darkModeOn;
@property (nonatomic, strong) NSImage *mainImage;
@property (nonatomic, strong) NSImage *alternateImage;
@property (nonatomic, strong) NSImage *squelchImage;

- (void)startAnimation;
- (void)stopAnimation;
@end
