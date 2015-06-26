//
//  GrowlHistoryNotification.h
//  Growl
//
//  Created by Daniel Siemer on 8/17/10.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GrowlImageCache;

@interface GrowlHistoryNotification : NSManagedObject {

}
@property (nonatomic, strong) NSString * AppID;
@property (nonatomic, strong) NSString * ApplicationName;
@property (nonatomic, strong) NSString * Description;
@property (nonatomic, strong) NSString * Name;
@property (nonatomic, strong) NSDate   * Time;
@property (nonatomic, strong) NSString * Title;
@property (nonatomic, strong) NSNumber * Priority;
@property (nonatomic, strong) NSString * Identifier;
@property (nonatomic, strong) GrowlImageCache *Image;
@property (nonatomic, strong) NSNumber * deleteUponReturn;
@property (nonatomic, strong) NSNumber * showInRollup;
@property (nonatomic, strong) id GrowlDictionary;

-(void)setWithNoteDictionary:(NSDictionary*)noteDict;
-(NSString*)hashForData:(NSData*)data;

@end
