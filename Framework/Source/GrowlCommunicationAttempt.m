//
//  GrowlCommunicationAttempt.m
//  Growl
//
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlCommunicationAttempt.h"

@implementation GrowlCommunicationAttempt

+ (GrowlCommunicationAttemptType) attemptType {
	NSAssert1(NO, @"attemptType message received by class %@, which does not override it!", self);
	return GrowlCommunicationAttemptTypeNone;
}

@synthesize dictionary;
@synthesize attemptType;
@synthesize nextAttempt;
@synthesize delegate;
@synthesize error;

- (instancetype) initWithDictionary:(NSDictionary *)dict {
	if ((self = [super init])) {
		dictionary = dict;
		attemptType = [[self class] attemptType];
      nextAttempt = nil;
      _finished = NO;
	}
	return self;
}


- (id) makeNextAttemptOfClass:(Class)classToTryNext {
	NSAssert1([classToTryNext isSubclassOfClass:[GrowlCommunicationAttempt class]], @"Can't make a communication attempt from %@, which is not a subclass of GrowlCommunicationAttempt", classToTryNext);
	NSAssert1(classToTryNext != [GrowlCommunicationAttempt class], @"Can't directly instantiate %@", classToTryNext);
	NSAssert2(self.nextAttempt, @"Trying to have %@ create its next attempt while it already has one (%@)!", self, self.nextAttempt);
    
	GrowlCommunicationAttempt *next = [[classToTryNext alloc] initWithDictionary:self.dictionary];
	self.nextAttempt = next;
	return next;
}

- (void) begin {
	NSAssert1(NO, @"Subclass dropped the ball: %@ does not implement -begin!", self);
}

- (void) wasNotDisplayed{
   if(self.delegate && [self.delegate respondsToSelector:@selector(notificationWasNotDisplayed:)])
      [self.delegate notificationWasNotDisplayed:self];
   [self stopAttempts];
}
- (void) queueAndReregister{
    //Called when we get that we aren't registered
    [self.delegate queueAndReregister:self];
    [self stopAttempts];
    [self finished];
}
- (void) stopAttempts {
    GrowlCommunicationAttempt *next = self.nextAttempt;
    while(next != nil){
        GrowlCommunicationAttempt __attribute__((unused)) *temp = next;
        [next finished];
        next = next.nextAttempt;
    }
    
    if(delegate && [delegate respondsToSelector:@selector(stoppedAttempts:)])
        [self.delegate stoppedAttempts:self];
}
- (void) succeeded {
	[self.delegate attemptDidSucceed:self];
    [self stopAttempts];
}
- (void) failed {
	[self.nextAttempt begin];
	[self.delegate attemptDidFail:self];
}
- (void) finished {
   if(_finished)
      return;
   _finished = YES;
   [self.delegate finishedWithAttempt:self];
}

@end
