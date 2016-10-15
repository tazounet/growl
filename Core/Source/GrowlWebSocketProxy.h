//
//  GrowlWebSocketProxy.h
//  Growl
//
//  Created by Daniel Siemer on 11/4/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@class GCDAsyncSocket;

@interface GrowlWebSocketProxy : NSObject <GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, unsafe_unretained) id delegate;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSocket:(GCDAsyncSocket*)socket NS_DESIGNATED_INITIALIZER;

- (void)disconnect;

- (NSString *)connectedHost;
- (NSData *)connectedAddress;

- (id)userData;
- (void)setUserData:(id)userInfo;

- (void)readDataToData:(NSData *)data
				withLength:(NSUInteger)length
			  withTimeout:(NSTimeInterval)timeout
						 tag:(long)tag;
- (void)readDataToLength:(NSUInteger)length withTimeout:(NSTimeInterval)timeout tag:(long)tag;
- (void)readDataToData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag;
- (void)writeData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag;

@end
