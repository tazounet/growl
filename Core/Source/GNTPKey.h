//
//  GNTPKey.h
//  Growl
//
//  Created by Rudy Richter on 10/10/09.
//  Copyright 2009 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlGNTPDefines.h"

NSString *HexEncode(NSData *data);
NSMutableData *HexUnencode(NSString* string);

@interface GNTPKey : NSObject 
{
	GrowlGNTPHashingAlgorithm _hashAlgorithm;
	GrowlGNTPEncryptionAlgorithm _encryptionAlgorithm;
	NSString *_password;
	NSData *_salt;
	NSData *_encryptionKey;
	NSData *_keyHash;

	NSData *_iv;
}

+ (BOOL)isSupportedHashAlgorithm:(NSString*)hash;
+ (BOOL)isSupportedEncryptionAlgorithm:(NSString*)algorithm;
+ (GrowlGNTPEncryptionAlgorithm)encryptionAlgorithmFromString:(NSString*)algorithm;
+ (GrowlGNTPHashingAlgorithm)hashingAlgorithmFromString:(NSString*)algorithm;

- (instancetype)initWithPassword:(NSString*)password hashAlgorithm:(GrowlGNTPHashingAlgorithm)hashAlgorithm encryptionAlgorithm:(GrowlGNTPEncryptionAlgorithm)encryptionAlgorithm NS_DESIGNATED_INITIALIZER;
+ (NSData *)generateSalt:(int)length;
- (void)generateSalt;
- (void)generateKey;
- (NSString*)hashAlgorithmString;
- (NSString*)encryptionAlgorithmString;
- (NSData*)encrypt:(NSData*)bytes;
- (NSData*)decrypt:(NSData*)bytes;

- (NSData*)generateIV;

- (NSString*)key;
- (NSString*)encryption;

@property (assign) GrowlGNTPHashingAlgorithm hashAlgorithm;
@property (assign) GrowlGNTPEncryptionAlgorithm encryptionAlgorithm;
@property (strong) NSData *encryptionKey;
@property (strong) NSData *keyHash;
@property (strong) NSString *password;
@property (strong) NSData *salt;
@property (strong) NSData *IV;

@end
