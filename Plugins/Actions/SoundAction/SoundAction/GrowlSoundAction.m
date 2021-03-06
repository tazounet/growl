//
//  GrowlSoundAction.m
//  SoundAction
//
//  Created by Daniel Siemer on 3/15/12.
//  Copyright 2012 The Growl Project, LLC. All rights reserved.
//

#import "GrowlSoundAction.h"
#import "GrowlSoundActionDefines.h"
#import "GrowlSoundActionPreferencePane.h"

#include <CoreAudio/AudioHardware.h>

@implementation GrowlSoundAction

@synthesize audioDeviceId;
@synthesize currentSound;
@synthesize queuedSounds;

- (instancetype)init
{
	if ((self = [super init])) {
		self.audioDeviceId = nil;
		sound_queue = dispatch_queue_create("com.growl.soundaction.sounddispatchqueue", DISPATCH_QUEUE_SERIAL);
		self.queuedSounds = [NSMutableArray array];
	}
	return self;
}

+ (NSString*)getAudioDevice
{
	NSString *result = nil;
	AudioObjectPropertyAddress propertyAddress = {kAudioHardwarePropertyDefaultSystemOutputDevice, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMaster};
	UInt32 propertySize;
	
	if(AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propertySize) == noErr)
	{
		AudioObjectID deviceID;
		if(AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propertySize, &deviceID) == noErr)
		{
			CFStringRef UID = NULL;
			propertySize = sizeof(UID);
			propertyAddress.mSelector = kAudioDevicePropertyDeviceUID;
			propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
			propertyAddress.mElement = kAudioObjectPropertyElementMaster;
			if (AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, NULL, &propertySize, &UID) == noErr)
			{
				result = (__bridge NSString *)UID;
			}
		}
	}
	return result;    
}

-(void)dispatchNotification:(NSDictionary *)notification withConfiguration:(NSDictionary *)configuration {
	NSString *name = [configuration valueForKey:SelectedSoundPref];
	if(name && [name caseInsensitiveCompare:GrowlSystemDefaultSound] != NSOrderedSame){
		NSSound *soundToPlay = [NSSound soundNamed:name];
		if(!soundToPlay){
			NSLog(@"No sound named %@", name);
			return;
		}
		if(!audioDeviceId)
			self.audioDeviceId = [GrowlSoundAction getAudioDevice];
		soundToPlay.playbackDeviceIdentifier = audioDeviceId;
		soundToPlay.delegate = self;
		
		NSUInteger volume = SoundVolumeDefault;
		if([configuration valueForKey:SoundVolumePref])
			volume = [[configuration valueForKey:SoundVolumePref] unsignedIntegerValue];
		
		soundToPlay.volume = ((CGFloat)volume / 100.0f);
		
		__weak GrowlSoundAction *weakSelf = self;
		dispatch_async(sound_queue, ^{
			if(!weakSelf.currentSound){
				weakSelf.currentSound = soundToPlay;
				[soundToPlay play];
			}else {
				[weakSelf.queuedSounds addObject:soundToPlay];
			}
		});
	}else{
		NSBeep();
	}
}

- (GrowlPluginPreferencePane *) preferencePane {
	if (!_preferencePane)
		_preferencePane = [[GrowlSoundActionPreferencePane alloc] initWithBundle:[NSBundle bundleForClass:[self class]]];
	
	return _preferencePane;
}

-(void)sound:(NSSound *)sound didFinishPlaying:(BOOL)aBool {
	__weak GrowlSoundAction *weakSelf = self;
	dispatch_async(sound_queue, ^{
		weakSelf.currentSound = nil;
		if((weakSelf.queuedSounds).count > 0){
			NSSound *newSound = (weakSelf.queuedSounds)[0U];
			weakSelf.currentSound = newSound;
			[weakSelf.queuedSounds removeObjectAtIndex:0U];
			[newSound play];
		}
	});
}

@end
