//
//  GrowlSubscriptionCellView.m
//  Growl
//
//  Created by Daniel Siemer on 1/12/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlSubscriptionCellView.h"

@implementation GrowlSubscriptionCellView

@synthesize validUntilLabel;

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
   if((self = [super initWithCoder:aDecoder])){
      self.validUntilLabel = NSLocalizedString(@"Valid until:", @"Column title for how long a subscriber is valid for");
   }
   return self;
}


@end
