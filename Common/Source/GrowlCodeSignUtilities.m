//
//  GrowlCodeSignUtilities.m
//  GrowlTunes
//
//  Created by Daniel Siemer on 12/11/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlCodeSignUtilities.h"
#import <Security/CodeSigning.h>

@implementation GrowlCodeSignUtilities

+ (BOOL) hasEntitlement:(NSString*)entitlement
{
	BOOL result = NO;
    CFErrorRef errors = NULL;
	SecCodeRef code = NULL;
	SecRequirementRef requirement = NULL;
	OSStatus status = errSecSuccess;
	
	status = SecCodeCopySelf(kSecCSDefaultFlags, &code);
	if (status == errSecSuccess)
    {    
        NSString *requirementString = [NSString stringWithFormat:@"entitlement[\"%@\"] exists", entitlement];
        status = SecRequirementCreateWithStringAndErrors((__bridge CFStringRef)requirementString, kSecCSDefaultFlags, &errors, &requirement);
        if (status == errSecSuccess)
        {
            status = SecCodeCheckValidity(code, kSecCSDefaultFlags, requirement);
            if (status == errSecSuccess)
            {
                result = YES;
            }
        }
    }
    
    if(code)
        CFRelease(code);
    if(requirement)
        CFRelease(requirement);
    
    if(status != errSecSuccess)
        NSLog(@"SecCodeCopySelf failed with status code: %ld", (long)status);
    if(errors)
    {
        CFDictionaryRef errDict = CFErrorCopyUserInfo(errors);
        NSLog(@"SecRequirementCreateWithStringAndErrors failure: %@", (__bridge NSDictionary*)errDict);
        CFRelease(errDict), errDict = NULL;
        CFRelease(errors), errors = NULL;
    }
    if(!result)
        NSLog(@"Entitlement NOT present: %@", entitlement);
    return result;
}

+ (BOOL) hasSandboxEntitlement {
	return [self hasEntitlement:@"com.apple.security.app-sandbox"];
}

+ (BOOL) hasNetworkClientEntitlement {
	return [self hasEntitlement:@"com.apple.security.network.client"];
}

+ (BOOL) hasNetworkServerEntitlement {
	return [self hasEntitlement:@"com.apple.security.network.server"];
}

+ (BOOL) isSandboxed {
	return [self hasSandboxEntitlement];
}

@end
