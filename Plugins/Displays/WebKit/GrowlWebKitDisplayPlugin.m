//
//  GrowlWebKitDisplayPlugin.h
//  Growl
//
//  Created by JKP on 13/11/2005.
//	Copyright 2005–2011 The Growl Project. All rights reserved.
//

#import "GrowlWebKitDisplayPlugin.h"
#import "GrowlWebKitDefines.h"
#import "GrowlWebKitPrefsController.h"
#import "GrowlWebKitWindowController.h"
#import "GrowlDefines.h"

@implementation GrowlWebKitDisplayPlugin

- (id) initWithStyleBundle:(NSBundle *)styleBundle {
	if ((self = [super initWithBundle:styleBundle])) {
		NSDictionary *styleInfo = [styleBundle infoDictionary];
		style = [styleInfo valueForKey:@"CFBundleName"];
		prefDomain = [[NSString alloc] initWithFormat:@"%@.%@", GrowlWebKitPrefDomain, style];
		windowControllerClass = NSClassFromString(@"GrowlWebKitWindowController");

		BOOL validBundle = YES;
		/* NOTE verification here....does the plist contain all the relevant keys? does the
			bundle contain all the files we need? */

		if (!validBundle) {
			return nil;
		}
	}

	return self;
}

- (GrowlPluginPreferencePane *) preferencePane {
	if (!_preferencePane) {
		// load GrowlWebKitPrefsController dynamically so that GHA does not
		// have to link against it and all of its dependencies
		Class prefsController = NSClassFromString(@"GrowlWebKitPrefsController");
		_preferencePane = [[prefsController alloc] initWithStyle:style];
	}
	return _preferencePane;
}

- (BOOL)requiresPositioning {
	return YES;
}

@end
