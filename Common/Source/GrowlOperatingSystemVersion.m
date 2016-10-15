//
//  GrowlOperatingSystemVersion.m
//  Growl
//
//  Created by Evan Schoenberg on 11/5/08.
//

#import "GrowlOperatingSystemVersion.h"

void GrowlGetSystemVersion(NSUInteger *outMajor, NSUInteger *outMinor, NSUInteger *outIncremental)
{
    if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_10)
    {
        NSOperatingSystemVersion version = [NSProcessInfo processInfo].operatingSystemVersion;
        if (outMajor) *outMajor = version.majorVersion;
        if (outMinor) *outMinor = version.minorVersion;
        if (outIncremental) *outIncremental = version.patchVersion;
    }
    else
    {
        NSLog(@"Unable to obtain system version");
        if (outMajor) *outMajor = 10;
        if (outMinor) *outMinor = 0;
        if (outIncremental) *outIncremental = 0;
    }
}
