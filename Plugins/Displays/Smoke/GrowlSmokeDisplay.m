//
//  GrowlSmokeDisplay.m
//  Display Plugins
//
//  Created by Matthew Walton on 09/09/2004.
//  Copyright 2004–2011 The Growl Project. All rights reserved.
//

#import <GrowlPlugins/GrowlNotification.h>
#import "GrowlSmokeDisplay.h"
#import "GrowlSmokeWindowController.h"
#import "GrowlSmokePrefsController.h"
#import "GrowlSmokeDefines.h"
#import "GrowlDefinesInternal.h"

@implementation GrowlSmokeDisplay

- (instancetype) init {
	if ((self = [super init])) {
		windowControllerClass = NSClassFromString(@"GrowlSmokeWindowController");
		self.prefDomain = GrowlSmokePrefDomain;
	}
	return self;
}


- (GrowlPluginPreferencePane *) preferencePane {
	if (!_preferencePane)
		_preferencePane = [[GrowlSmokePrefsController alloc] initWithBundle:[NSBundle bundleForClass:[self class]]];
	return _preferencePane;
}

@end
