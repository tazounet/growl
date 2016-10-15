//
//  GNTPSubscriberEntry.h
//  Growl
//
//  Created by Daniel Siemer on 11/22/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GrowlCommunicationAttempt.h"

@class GNTPKey, GNTPSubscribePacket, GrowlGNTPCommunicationAttempt, GrowlGNTPSubscriptionAttempt;

@interface GNTPSubscriberEntry : NSObject <GrowlCommunicationAttemptDelegate>

@property (nonatomic, strong) NSString *computerName;
@property (nonatomic, strong) NSString *addressString;
@property (nonatomic, strong) NSString *domain;
@property (nonatomic, strong) NSData *lastKnownAddress;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *subscriberID;
@property (nonatomic, strong) NSString *uuid;
@property (nonatomic, strong) GNTPKey *key;
@property (nonatomic, strong) NSTimer *resubscribeTimer;

@property (nonatomic, strong) NSDate *initialTime;
@property (nonatomic, strong) NSDate *validTime;
@property (nonatomic) NSInteger timeToLive;
@property (nonatomic) NSInteger subscriberPort;
@property (nonatomic) BOOL remote;
@property (nonatomic) BOOL manual;
@property (nonatomic) BOOL use;
@property (nonatomic) BOOL active;

@property (nonatomic) BOOL alreadyBrowsing;
@property (nonatomic) BOOL attemptingToSubscribe;
@property (nonatomic) BOOL subscriptionError;
@property (nonatomic, strong) NSString* subscriptionErrorDescription;

@property (nonatomic, strong) GrowlGNTPSubscriptionAttempt *subscriptionAttempt;

-(instancetype)initWithName:(NSString*)name
              addressString:(NSString*)addrString
                     domain:(NSString*)aDomain
                    address:(NSData*)addrData
                       uuid:(NSString*)aUUID
               subscriberID:(NSString*)subID
                     remote:(BOOL)isRemote
                     manual:(BOOL)isManual
                        use:(BOOL)shouldUse
                initialTime:(NSDate*)date
                 timeToLive:(NSInteger)ttl
                       port:(NSInteger)port NS_DESIGNATED_INITIALIZER;

-(instancetype)init NS_UNAVAILABLE;
-(instancetype)initWithDictionary:(NSDictionary*)dict;
-(instancetype)initWithPacket:(GNTPSubscribePacket*)packet;

-(void)updateRemoteWithPacket:(GNTPSubscribePacket*)packet;
-(void)updateLocalWithPacket:(GrowlGNTPCommunicationAttempt*)packet error:(BOOL)wasError;
-(void)subscribe;

-(void)invalidate;
-(NSDictionary*)dictionaryRepresentation;

@end
