//
//  GrowlSoundAction.h
//  SoundAction
//
//  Created by Daniel Siemer on 3/15/12.
//  Copyright 2012 The Growl Project, LLC. All rights reserved.
//

#import "GrowlActionPlugin.h"

@interface GrowlSoundAction : GrowlActionPlugin <GrowlDispatchNotificationProtocol, NSSoundDelegate> {
	dispatch_queue_t sound_queue;
}

@property (nonatomic, strong) NSString *audioDeviceId;
@property (nonatomic, strong) NSSound *currentSound;
@property (nonatomic, strong) NSMutableArray *queuedSounds;

@end
