//
//  NSURL+StringEncoding.m
//  Boxcar
//
//  Created by Daniel Siemer on 4/10/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "NSURL+StringEncoding.h"

@implementation NSURL (StringEncoding)

+(NSString*)encodedStringByAddingPercentEscapesToString:(NSString*)string {
    NSCharacterSet *queryKVSet = [NSCharacterSet
                                  characterSetWithCharactersInString:@";/?:@&=+$"
                                 ].invertedSet;

    NSString *encodedString = [string stringByAddingPercentEncodingWithAllowedCharacters:queryKVSet];

	return encodedString;
}

@end
