//
//  GrowlBrowserEntry.h
//  Growl
//
//  Created by Ingmar Stein on 16.04.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GNTPForwarder, GNTPKey;

@interface GrowlBrowserEntry : NSObject {
	
	NSString				*_name;
	NSString          *_domain;
	NSString				*_uuid;
	BOOL					_use;
	BOOL					_active;
	BOOL              _manualEntry;
	
	NSString				*password;
	GNTPKey           *_key;
	BOOL					didPasswordLookup;
	GNTPForwarder		*owner;
   
	NSData            *_lastKnownAddress;
}
- (instancetype) initWithDictionary:(NSDictionary *)dict;
- (instancetype) initWithComputerName:(NSString *)name;

- (void)updateKey;
- (NSString *) password;
- (void) setPassword:(NSString *)password;

- (NSMutableDictionary *) properties;

- (void) setOwner:(GNTPForwarder *)pref;

@property (strong) NSString *uuid;
@property (nonatomic, strong) NSString *computerName;
@property (nonatomic, assign) BOOL use;
@property (nonatomic, assign) BOOL active;
@property (assign) BOOL manualEntry;
@property (strong) NSString *domain;
@property (strong) GNTPKey *key;
@property (nonatomic, strong) NSData *lastKnownAddress;
@end
