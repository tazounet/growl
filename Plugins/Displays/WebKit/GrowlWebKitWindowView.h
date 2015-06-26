//
//  GrowlWebKitWindowView.h
//  Growl
//
//  Created by Ingmar Stein on Thu Apr 14 2005.
//  Copyright 2005–2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "GrowlNotificationView.h"

@interface WebView(Transparency)
- (void) setDrawsBackground:(BOOL)flag;
- (BOOL) drawsBackground;
@end

@interface GrowlWebKitWindowView : WebView {
	BOOL				initialDisplayTest;
	BOOL				mouseOver;
	BOOL				realHitTest;
	BOOL				closeOnMouseExit;
	SEL					action;
	id					target;
	NSTrackingRectTag	trackingRectTag;
	
	NSRect				closeButtonRect;
}

@property (nonatomic, strong) NSBundle *styleBundle;

- (void) sizeToFit;

- (id) target;
- (void) setTarget:(id)object;

- (SEL) action;
- (void) setAction:(SEL)selector;

- (BOOL) mouseOver;
- (void) setCloseOnMouseExit:(BOOL)flag;

- (void) mouseEnteredNotificationView:(GrowlNotificationView *)notificationView;
- (void) mouseExitedNotificationView:(GrowlNotificationView *)notificationView;
- (void) stopDisplay;

@end
