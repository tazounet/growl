//
//	GrowlDisplayPlugin.m
//	Growl
//
//	Created by Peter Hosey on 2005-06-01.
//	Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import <GrowlPlugins/GrowlDisplayPlugin.h>
#import <GrowlPlugins/GrowlDisplayWindowController.h>
#import "GrowlDisplayBridgeController.h"
#import "NSStringAdditions.h"
#import "GrowlDefines.h"
#import <GrowlPlugins/GrowlNotification.h>
#import <GrowlPlugins/GrowlNotificationView.h>

NSString *GrowlDisplayPluginInfoKeyUsesQueue = @"GrowlDisplayUsesQueue";
NSString *GrowlDisplayPluginInfoKeyWindowNibName = @"GrowlDisplayWindowNibName";

@implementation GrowlDisplayPlugin

- (instancetype) initWithBundle:(NSBundle *)bundle {
	if ((self = [super initWithBundle:bundle])) {
		/*determine whether this display should enqueue notifications when a
		 *	notification is already being displayed.
		 */
		windowControllerClass    = nil;
		
		if(![self fullCustomButton]){
			NSImage *image = self.buttonImage;
			NSImage *pressed = self.pressedButtonImage;
			if(self.buttonKey && (image || pressed)){
				[GrowlNotificationView makeButtonWithImage:image pressedImage:pressed forKey:self.buttonKey];
			}
		}
	}
	return self;
}


-(BOOL)fullCustomButton {
	return NO;
}
-(NSString*)buttonKey {
	return self.bundle.bundleIdentifier;
}
-(NSImage*)buttonImage {
	NSString *imageName = self.bundle.infoDictionary[@"GrowlCloseButtonImage"];
	if(!imageName)
		return nil;
	
	NSString *path = [self.bundle pathForImageResource:imageName];
	NSImage *image = [[NSImage alloc] initWithContentsOfFile:path];
	return image;
}
-(NSImage*)pressedButtonImage {
	NSString *imageName = self.bundle.infoDictionary[@"GrowlCloseButtonPressedImage"];
	if(!imageName)
		return nil;
	
	NSString *path = [self.bundle pathForImageResource:imageName];
	NSImage *image = [[NSImage alloc] initWithContentsOfFile:path];
	return image;
}

#pragma mark -

- (void)dispatchNotification:(NSDictionary *)noteDict withConfiguration:(NSDictionary *)configuration {
	GrowlNotification *notification = [GrowlNotification notificationWithDictionary:noteDict 
																					  configurationDict:configuration];
	NSString *windowNibName = self.windowNibName;
	GrowlDisplayWindowController *thisWindow = nil;
	
	NSString *identifier = [notification.auxiliaryDictionary valueForKey:GROWL_NOTIFICATION_IDENTIFIER];
	
	if (identifier) {
		thisWindow = coalescableWindows[identifier];
	}
	
	if (thisWindow) {
		//Tell the bridge to update its displayed notification
		[thisWindow updateToNotification:notification];
		
	} else {
		//No existing bridge on this identifier, or no identifier. Create one.
		if (windowNibName)
			thisWindow = [[windowControllerClass alloc] initWithWindowNibName:windowNibName];
		else
			thisWindow = [[windowControllerClass alloc] initWithNotification:notification plugin:self];
      
      if(thisWindow != nil){
         thisWindow.notification = notification;
         
         [thisWindow startDisplay];
         
         if (identifier) {
            if (!coalescableWindows) coalescableWindows = [[NSMutableDictionary alloc] init];
            coalescableWindows[identifier] = thisWindow;
         }
      }else{
         NSLog(@"Error! Unable to make a display of class %@", NSStringFromClass(windowControllerClass));
      }
	}
}

- (NSString *) windowNibName {
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];

	NSString *windowNibName = [bundle objectForInfoDictionaryKey:GrowlDisplayPluginInfoKeyWindowNibName];
	if (windowNibName) {
		NSAssert4([windowNibName isKindOfClass:[NSString class]],
				  @"object for %@ in Info.plist of %@ is a %@, not a string (description follows)\n%@",
				  GrowlDisplayPluginInfoKeyWindowNibName,
				  bundle, [windowNibName class], windowNibName);
	}

	return windowNibName;
}

- (BOOL) requiresPositioning {
	return YES;
}

#pragma mark -

- (void) displayWindowControllerDidTakeDownWindow:(GrowlDisplayWindowController *)wc {
	@autoreleasepool {
		
		
		if (coalescableWindows) {
			NSString *identifier = wc.notification.auxiliaryDictionary[GROWL_NOTIFICATION_IDENTIFIER];
			if (identifier)
				[coalescableWindows removeObjectForKey:identifier];
		}
		
	}
}

@end
