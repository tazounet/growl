//
//  NSWorkspaceAdditions.m
//  Growl
//
//  Created by Ingmar Stein on 16.05.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "NSWorkspaceAdditions.h"
#include <ApplicationServices/ApplicationServices.h>

@implementation NSWorkspace (GrowlAdditions)

- (NSImage *) iconForApplication:(NSString *) inName {
	NSString *path = [self fullPathForApplication:inName];
	NSImage *appIcon = path ? [self iconForFile:path] : nil;

	if (appIcon)
		appIcon.size = NSMakeSize(128.0,128.0);

	return appIcon;
}

- (BOOL) getFileType:(out NSString **)outFileType forURL:(NSURL *)URL {
	NSParameterAssert(URL != nil);

    NSError *error;
    return [URL getResourceValue:outFileType forKey:NSURLTypeIdentifierKey error:&error];
}

- (BOOL) getFileType:(out NSString **)outFileType forFile:(NSString *)path {
	NSURL *URL = [[NSURL alloc] initFileURLWithPath:path];
	BOOL success = [self getFileType:outFileType forURL:URL];
	return success;
}

@end
