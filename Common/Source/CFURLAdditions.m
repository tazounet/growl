//
//  CFURLAdditions.c
//  Growl
//
//  Created by Karl Adam on Fri May 28 2004.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#include "CFURLAdditions.h"
#include <stdbool.h>
#include <Carbon/Carbon.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#import <Foundation/Foundation.h>

static NSString *_CFURLAliasDataKey  = @"_CFURLAliasData";
static NSString *_CFURLStringKey     = @"_CFURLString";
static NSString *_CFURLStringTypeKey = @"_CFURLStringType";

//these are the type of external representations used by Dock.app.
NSURL *fileURLWithDockDescription(NSDictionary *dict) {
	NSURL *url = nil;

	NSString *path      = [dict valueForKey:_CFURLStringKey];
	NSData *aliasData = [dict valueForKey:_CFURLAliasDataKey];

	if (aliasData)
        NSLog(@"%@", aliasData);
		//url = fileURLWithAliasData(aliasData);

	if (!url) {
		if (path) {
			NSNumber *pathStyleNum = [dict valueForKey:_CFURLStringTypeKey];
			CFURLPathStyle pathStyle = kCFURLPOSIXPathStyle;
			
			if (pathStyleNum)
				pathStyle = pathStyleNum.intValue;

			char *filename;
         CFIndex size = CFStringGetMaximumSizeOfFileSystemRepresentation((CFStringRef)path);
         filename  = malloc(size);
            [path getFileSystemRepresentation:filename maxLength:size];
			int fd = open(filename, O_RDONLY, 0);
			free(filename);
			if (fd != -1) {
				struct stat sb;
				fstat(fd, &sb);
				close(fd);
				url = (NSURL*)CFBridgingRelease(CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)path, pathStyle, /*isDirectory*/ (bool)(sb.st_mode & S_IFDIR)));
			}
		}
	}

	return url;
}

NSDictionary *dockDescriptionWithURL(NSURL *theURL) {
	NSMutableDictionary *dict;

	if (!theURL) {
		NSLog(@"in createDockDescriptionWithURL: Cannot copy Dock description for a NULL URL");
		return NULL;
	}

	CFStringRef path   = CFURLCopyFileSystemPath((CFURLRef)theURL, kCFURLPOSIXPathStyle);
    NSData* aliasData  = nil; //createAliasDataWithURL(theURL);

	if (path || aliasData) {
		dict = [NSMutableDictionary dictionary];

		if (path) {
			[dict setValue:(__bridge NSString*)path forKey:_CFURLStringKey];
			CFRelease(path);
            [dict setValue:@(kCFURLPOSIXPathStyle) forKey:_CFURLStringTypeKey];
		}

		if (aliasData) {
			[dict setValue:aliasData forKey:_CFURLAliasDataKey];
		}
	} else {
		dict = NULL;
	}

	return dict;
}
