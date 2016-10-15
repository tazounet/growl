//
//  GrowlMistWindowController.h
//
//  Created by Rachel Blackman on 7/13/11.
//

#import <Cocoa/Cocoa.h>

#import "GrowlMistView.h"

@class GrowlMistWindowController;

@protocol GrowlMistWindowControllerDelegate
@optional
- (void)mistNotificationDismissed:(GrowlMistWindowController *)window;
- (void)mistNotificationClicked:(GrowlMistWindowController *)window;
- (void)closeAllNotifications:(GrowlMistWindowController *)window;
@end


@interface GrowlMistWindowController : NSWindowController <NSAnimationDelegate> {
	GrowlMistView				*mistView;
	NSViewAnimation 			*fadeAnimation;
	NSTimer						*lifetime;
   NSString                *uuid;
	BOOL						 closed;
	BOOL						 sticky;
	BOOL						 visible;
	BOOL						 selected;
	id							 __strong delegate;
}

@property (nonatomic,readwrite,strong) NSViewAnimation *fadeAnimation;
@property (nonatomic,readwrite,strong) NSTimer *lifetime;
@property (nonatomic,readonly) BOOL sticky;
@property (nonatomic,readonly) BOOL visible;
@property (nonatomic,readonly) BOOL selected;
@property (nonatomic,readonly) NSString *uuid;
@property (nonatomic,strong) id delegate;

- (instancetype)initWithNotificationTitle:(NSString *)title
                                     text:(NSString *)text
                                    image:(NSImage *)image
                                   sticky:(BOOL)isSticky
                                     uuid:(NSString*)uuid
                                 delegate:(id)delegate NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithWindow:(NSWindow *)window NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

- (void)fadeIn;
- (void)fadeOut;

@end
