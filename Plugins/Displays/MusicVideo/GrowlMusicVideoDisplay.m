//
//  GrowlMusicVideoDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//
#import <GrowlPlugins/GrowlNotification.h>
#import "GrowlMusicVideoDisplay.h"
#import "GrowlMusicVideoWindowController.h"
#import "GrowlMusicVideoPrefs.h"
#import "GrowlDefinesInternal.h"

@implementation GrowlMusicVideoDisplay

- (instancetype) init {
	if ((self = [super init])) {
		windowControllerClass = NSClassFromString(@"GrowlMusicVideoWindowController");
		self.prefDomain = GrowlMusicVideoPrefDomain;
	}
	return self;
}


- (GrowlPluginPreferencePane *) preferencePane {
	if (!_preferencePane)
		_preferencePane = [[GrowlMusicVideoPrefs alloc] initWithBundle:[NSBundle bundleForClass:[self class]]];
	return _preferencePane;
}

- (BOOL) requiresPositioning {
	return NO;
}

@end
