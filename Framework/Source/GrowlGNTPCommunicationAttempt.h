//
//  GrowlGNTPCommunicationAttempt.h
//  Growl
//
//  Created by Peter Hosey on 2011-07-14.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlCommunicationAttempt.h"
#import "GCDAsyncSocket.h"
#import <xpc/xpc.h>

@class GCDAsyncSocket;
@class GNTPKey;

@interface GrowlGNTPCommunicationAttempt : GrowlCommunicationAttempt <GCDAsyncSocketDelegate>
{
@private
	GNTPKey *_key;
	GCDAsyncSocket *socket;
	NSString *responseParseErrorString, *bogusResponse;
	NSMutableDictionary *callbackHeaderItems;
	BOOL attemptSucceeded;
	int responseReadType;
	
	NSString *host;
	NSData *_addressData;
	NSString *password;
	
	//For the XPC version
	xpc_connection_t _connection;
}

@property (nonatomic, strong) NSString *host;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) xpc_connection_t connection;
@property (nonatomic, strong) NSMutableDictionary *callbackHeaderItems;
@property (nonatomic, strong) GNTPKey *key;
@property (nonatomic, strong) NSData *addressData;

//Lazily constructs the packet for self.dictionary.
-(NSData*)outgoingData;

//Returns NO. Subclasses may overrido to conditionally or unconditionally return YES.
- (BOOL) expectsCallback;

- (void)parseError;
- (void)parseFeedback;

@end
