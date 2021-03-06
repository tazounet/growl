//
//  GrowlNotifyScriptCommand.m
//  Growl
//
//  Created by Patrick Linskey on Tue Aug 10 2004.
//  Copyright (c) 2004-2011 The Growl Project. All rights reserved.
//

/*
 *  Some sample scripts:
 *	tell application "GrowlHelperApp"
 *		notify with title "test" description "test description" icon of application "Mail.app"
 *	end tell
 *
 *	tell application "GrowlHelperApp"
 *		notify with title "test" description "test description" icon of file "file:///Applications" sticky yes
 *	end tell
 */

#import "GrowlNotifyScriptCommand.h"
#import "GrowlApplicationController.h"
#import "GrowlDefines.h"
#import "NSWorkspaceAdditions.h"
#import "GrowlImageAdditions.h"

#define KEY_TITLE					@"title"
#define KEY_DESC					@"description"
#define KEY_STICKY					@"sticky"
#define KEY_PRIORITY				@"priority"
#define KEY_IMAGE_URL				@"imageFromURL"
#define KEY_ICON_APP_NAME			@"iconOfApplication"
#define KEY_ICON_FILE				@"iconOfFile"
#define KEY_IMAGE					@"image"
#define KEY_PICTURE					@"pictImage"
#define KEY_APP_NAME				@"appName"
#define KEY_NOTIFICATION_NAME		@"notificationName"
#define KEY_NOTIFICATION_IDENTIFIER	@"identifier"
#define KEY_NOTIFICATION_CLICKBACK_TARGET @"callbackURL"

#define ERROR_EXCEPTION								1
#define ERROR_NOT_FILE_URL							2
#define ERROR_ICON_OF_FILE_PATH_INVALID				3
#define ERROR_ICON_OF_FILE_PATH_FILE_MISSING		4
#define ERROR_ICON_OF_FILE_PATH_NOT_IMAGE			5
#define ERROR_ICON_OF_FILE_UNSUPPORTED_PROTOCOL		6

NSString *IMAGE_FROM_LOCATION_DEPRECATION_URL = @"http://growl.info/documentation/faq.php#applescriptimagelocation";

static const NSSize iconSize = { 1024.0f, 1024.0f };

@implementation GrowlNotifyScriptCommand

- (id) performDefaultImplementation {
	NSDictionary *args = self.evaluatedArguments;

	//should validate params better!
	NSString *title             = args[KEY_TITLE];
	NSString *desc              = args[KEY_DESC];
	NSNumber *sticky            = args[KEY_STICKY];
	NSNumber *priority          = args[KEY_PRIORITY];
	NSString *imageUrl          = args[KEY_IMAGE_URL];
	NSString *iconOfFile        = args[KEY_ICON_FILE];
	NSString *iconOfApplication = args[KEY_ICON_APP_NAME];
	NSData   *imageData         = args[KEY_IMAGE];
	NSData   *pictureData       = args[KEY_PICTURE];
	NSString *appName           = args[KEY_APP_NAME];
	NSString *notifName         = args[KEY_NOTIFICATION_NAME];
	NSString *notifIdentifier   = args[KEY_NOTIFICATION_IDENTIFIER];
	NSString *callbackTarget    = args[KEY_NOTIFICATION_CLICKBACK_TARGET];

	if (!title || ![title isKindOfClass:[NSString class]]) title = @"";
	if (!desc || ![desc isKindOfClass:[NSString class]]) desc = @"";

	NSMutableDictionary *noteDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
		appName,   GROWL_APP_NAME,
		notifName, GROWL_NOTIFICATION_NAME,
		title,     GROWL_NOTIFICATION_TITLE,
		desc,      GROWL_NOTIFICATION_DESCRIPTION,
		nil];

	if (priority)
		noteDict[GROWL_NOTIFICATION_PRIORITY] = priority;

	if (sticky)
		noteDict[GROWL_NOTIFICATION_STICKY] = sticky;

	if (notifIdentifier)
		noteDict[GROWL_NOTIFICATION_IDENTIFIER] = notifIdentifier;
   
   if (callbackTarget)
      noteDict[GROWL_NOTIFICATION_CALLBACK_URL_TARGET] = callbackTarget;

    int pid = [NSProcessInfo processInfo].processIdentifier;
    noteDict[GROWL_APP_PID] = @(pid);

	@try {
		NSImage *icon = nil;
		NSURL   *url = nil;
        
		//Command used the "image from URL" argument
		if (imageUrl) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                NSLog(@"%@", [NSString stringWithFormat:@"'icon from location' is deprecated as of Growl 2.0, it will now fire using a generic icon.  To update your own applescript, see instructions here: %@, or contact the developer of your script and tell them they need to update their applescript.  This message will only show once.", IMAGE_FROM_LOCATION_DEPRECATION_URL]);
            });
            //we retain this icon because all the other paths assume an owning reference
            icon = [[NSWorkspace sharedWorkspace] iconForApplication:@"AppleScript Editor.app"];
		} else if (iconOfFile) {
			//Command used the "icon of file" argument
			if (!(url = [self fileUrlForLocationReference:iconOfFile])) {
				//NSLog(@"That's a no go on that file's icon.");
				return nil;
			}
			icon = [[NSWorkspace sharedWorkspace] iconForFile:url.path];
		} else if (iconOfApplication) {
			//Command used the "icon of application" argument
			icon = [[NSWorkspace sharedWorkspace] iconForApplication:iconOfApplication];
		} else if (imageData) {
			icon = [[NSImage alloc] initWithData:imageData];
		} else if (pictureData) {
			icon = [[NSImage alloc] initWithData:pictureData];
		}

		if (icon) {
			icon.size = iconSize;
			noteDict[GROWL_NOTIFICATION_ICON_DATA] = icon.PNGRepresentation;
		}

		[[GrowlApplicationController sharedController] dispatchNotificationWithDictionary:noteDict];
	} @catch(NSException *e) {
		NSLog(@"error processing AppleScript request: %@", e);
		[self setError:ERROR_EXCEPTION failure:e];
	}


	return nil;
}

//This method will attempt to locate an image given either a path or an URL
- (NSURL *) fileUrlForLocationReference:(NSString *)imageReference {
	NSURL   *url = nil;

	NSRange testRange = [imageReference rangeOfString: @"://"];
	if (!(testRange.location == NSNotFound)) {
		//It looks like a protocol string
		if (![imageReference hasPrefix: @"file://"]) {
			//The protocol is not valid  - we only accept file:// URLs
			[self setError:ERROR_NOT_FILE_URL];
			return nil;
		}

		//it was a file URL that was passed
		url = [NSURL URLWithString: imageReference];
		//Check that it's properly encoded
		if (!url.path) {
			//Try encoding the path to fit URL specs
            NSCharacterSet *set = [NSCharacterSet URLPathAllowedCharacterSet];
			url = [NSURL URLWithString: [imageReference stringByAddingPercentEncodingWithAllowedCharacters:set]];
			//Check it again
			if (!url.path) {
				//This path is just no good.
				[self setError:ERROR_ICON_OF_FILE_PATH_INVALID];
				return nil;
			}
		}
	} else {
		//it was an alias / path that was passed
		url = [NSURL fileURLWithPath:imageReference.stringByExpandingTildeInPath];
		if (!url) {
			[self setError:ERROR_ICON_OF_FILE_PATH_INVALID];
			return nil;
		}
	}

	//Sanity check the URL
	if (!url.fileURL) {
		//Bail - wrong protocol.
		[self setError:ERROR_NOT_FILE_URL];
		return nil;
	}
	if (!url) {
		[self setError:ERROR_ICON_OF_FILE_PATH_INVALID];
		return nil;
	}
	//Check to see if the file actually exists.
	if (![[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
		[self setError:ERROR_ICON_OF_FILE_PATH_FILE_MISSING];
		return nil;
	}
	return url;
}


- (void) setError:(int)errorCode {
	[self setError:errorCode failure:nil];
}

- (void)setError:(int)errorCode failure:(id)failure {
	self.scriptErrorNumber = errorCode;
	NSString *str;

	switch (errorCode) {
		case ERROR_EXCEPTION:
			str = [NSString stringWithFormat:@"Exception raised while processing: %@", failure];
			break;
		case ERROR_NOT_FILE_URL:
			str = @"Non-File URL.  If passing a URL to growl as a parameter, it must be a 'file://' URL.";
			break;
		case ERROR_ICON_OF_FILE_PATH_FILE_MISSING:
			str = @"'image from URL' parameter - File specified does not exist.";
			break;
		case ERROR_ICON_OF_FILE_PATH_INVALID:
			str = @"'image from URL' parameter - Badly formed path.";
			break;
		case ERROR_ICON_OF_FILE_PATH_NOT_IMAGE:
			str = @"'image from URL' parameter - Supplied file is not a valid image type.";
			break;
		case ERROR_ICON_OF_FILE_UNSUPPORTED_PROTOCOL:
			str = @"'image from URL' parameter - Unsupported URL protocol. (Only 'file://' supported)";
			break;
		default:
			str = nil;
	}

	if (str)
		self.scriptErrorString = str;
}

@end
