//
//  GrowlSoundActionPreferencePane.m
//  SoundAction
//
//  Created by Daniel Siemer on 3/15/12.
//  Copyright 2012 The Growl Project, LLC. All rights reserved.
//

#import "GrowlSoundActionPreferencePane.h"
#import "GrowlSoundActionDefines.h"

@interface GrowlSoundActionPreferencePane ()

@property (nonatomic, strong) NSString *soundTableTitle;
@property (nonatomic, strong) NSString *volumeLabel;

@end

@implementation GrowlSoundActionPreferencePane

@synthesize sounds;
@synthesize soundTableView;
@dynamic soundVolume;

@synthesize soundTableTitle;
@synthesize volumeLabel;

-(instancetype)initWithBundle:(NSBundle *)bundle {
	if((self = [super initWithBundle:bundle])){
		self.soundTableTitle = NSLocalizedStringFromTableInBundle(@"Sounds", @"Localizable", bundle, @"Sounds table title");
		self.volumeLabel = NSLocalizedStringFromTableInBundle(@"Volume:", @"Localizable", bundle, @"Volume slider label");
	}
	return self;
}


-(NSString*)mainNibName {
	return @"GrowlSoundActionPrefPane";
}

- (NSSet*)bindingKeys {
	static NSSet *keys = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keys = [NSSet setWithObjects:@"soundName",
									  @"sounds",
									  @"soundVolume", nil];
	});
	return keys;
}

-(void)updateConfigurationValues {
   self.soundTableView.delegate = nil;
	[self updateSoundsList];
	[super updateConfigurationValues];
	if((!self.soundName || ![sounds containsObject:self.soundName]) && sounds.count > 0){
		self.soundName = sounds[0U];
	}
	[soundTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[sounds indexOfObject:self.soundName]]
					byExtendingSelection:NO];
   self.soundTableView.delegate = self;
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification	{
	NSInteger selectedRow = soundTableView.selectedRow;
	if(selectedRow >= 0 && (NSUInteger)selectedRow < sounds.count){
		NSString *soundName = sounds[selectedRow];
		if([self.soundName caseInsensitiveCompare:soundName] != NSOrderedSame){
			self.soundName = soundName;
			if([soundName caseInsensitiveCompare:LocalizedSystemDefaultSound] == NSOrderedSame)
				NSBeep();
			else
				[[NSSound soundNamed:soundName] play];
         if([self respondsToSelector:@selector(_setDisplayName:)]){
            [self performSelector:@selector(_setDisplayName:) withObject:soundName];
         }
		}
	}
}

-(void)setSoundName:(NSString *)soundName {
	if([soundName caseInsensitiveCompare:LocalizedSystemDefaultSound] == NSOrderedSame)
		soundName = GrowlSystemDefaultSound;
	[self setConfigurationValue:soundName forKey:SelectedSoundPref];
}

-(NSString*)soundName {
	NSString *soundName = [self.configuration valueForKey:SelectedSoundPref];
	if([soundName isEqualToString:GrowlSystemDefaultSound])
		soundName = LocalizedSystemDefaultSound;
	return soundName;
}

-(void)setSoundVolume:(NSUInteger)volume {
	[self setConfigurationValue:@(volume) forKey:SoundVolumePref];
}

-(NSUInteger)soundVolume {
	NSUInteger volume = SoundVolumeDefault;
	if([self.configuration valueForKey:SoundVolumePref])
		volume = [[self.configuration valueForKey:SoundVolumePref] unsignedIntegerValue];
	return volume;
}

-(void)updateSoundsList {
	NSMutableArray *soundNames = [NSMutableArray array];
	
	NSArray *paths = @[@"/System/Library/Sounds",
                     @"/Library/Sounds",
                     [NSString stringWithFormat:@"%@/Library/Sounds", NSHomeDirectory()]];
   
	[paths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		BOOL isDirectory = NO;
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:obj isDirectory:&isDirectory]) {
			if (isDirectory) {
				
				NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:obj error:nil];
				for (NSString *filename in files) {
					NSString *file = filename.stringByDeletingPathExtension;
               
					if (![file isEqualToString:@".DS_Store"])
						[soundNames addObject:file];
				}
			}
		}
	}];
	[soundNames sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	[soundNames insertObject:LocalizedSystemDefaultSound atIndex:0];
	self.sounds = soundNames;
}

@end
