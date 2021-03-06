//
//  GrowlSpeechPrefs.m
//  Display Plugins
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004–2011 The Growl Project. All rights reserved.
//

#import "GrowlSpeechPrefs.h"
#import "GrowlSpeechDefines.h"
#import <AppKit/NSSpeechSynthesizer.h>
#import <ShortcutRecorder/ShortcutRecorder.h>
#import <GrowlPlugins/SGHotKey.h>
#import <GrowlPlugins/SGKeyCombo.h>

@interface GrowlSpeechPrefs ()

@property (nonatomic, strong) NSString *voiceLabel;
@property (nonatomic, strong) NSString *limitCharCheckboxTitle;
@property (nonatomic, strong) NSString *charactersLabel;
@property (nonatomic, strong) NSString *rateAdjustCheckbox;
@property (nonatomic, strong) NSString *slowLabel;
@property (nonatomic, strong) NSString *fastLabel;
@property (nonatomic, strong) NSString *volumeAdjustCheckbox;
@property (nonatomic, strong) NSString *globalHotkeysBoxLabel;
@property (nonatomic, strong) NSString *pauseResumeLabel;
@property (nonatomic, strong) NSString *skipNoteLabel;
@property (nonatomic, strong) NSString *clickNoteLabel;

@end

@implementation GrowlSpeechPrefs
@synthesize pauseShortcut;
@synthesize skipShortcut;
@synthesize clickShortcut;
@synthesize voices;

@dynamic useLimit;
@dynamic characterLimit;
@dynamic useRate;
@dynamic rate;
@dynamic useVolume;
@dynamic volume;

@synthesize voiceLabel;
@synthesize limitCharCheckboxTitle;
@synthesize charactersLabel;
@synthesize rateAdjustCheckbox;
@synthesize slowLabel;
@synthesize fastLabel;
@synthesize volumeAdjustCheckbox;
@synthesize globalHotkeysBoxLabel;
@synthesize pauseResumeLabel;
@synthesize skipNoteLabel;
@synthesize clickNoteLabel;

- (instancetype)initWithBundle:(NSBundle *)bundle {
   if((self = [super initWithBundle:bundle])){
      self.voiceLabel = NSLocalizedStringFromTableInBundle(@"Voice:", @"Localizable", bundle, @"Label for popup with voices");
		self.limitCharCheckboxTitle = NSLocalizedStringFromTableInBundle(@"Limit to", @"Localizable", bundle, @"Limit speech display to a given amount of characters");
		self.charactersLabel = NSLocalizedStringFromTableInBundle(@"characters", @"Localizable", bundle, @"label for the unit in the box for character limit");
		self.rateAdjustCheckbox = NSLocalizedStringFromTableInBundle(@"Adjust rate:", @"Localizable", bundle, @"Rate adjustment slider checkbox");
		self.slowLabel = NSLocalizedStringFromTableInBundle(@"Slow", @"Localizable", bundle, @"Label speech slower");
		self.fastLabel = NSLocalizedStringFromTableInBundle(@"Fast:", @"Localizable", bundle, @"Label for speech faster");
		self.volumeAdjustCheckbox = NSLocalizedStringFromTableInBundle(@"Volume:", @"Localizable", bundle, @"Volume adjustment checkcbox");
		self.globalHotkeysBoxLabel = NSLocalizedStringFromTableInBundle(@"Global Hotkeys:", @"Localizable", bundle, @"Label for box containing global hot keys for the speech display");
		self.pauseResumeLabel = NSLocalizedStringFromTableInBundle(@"Pause/Resume", @"Localizable", bundle, @"Label for hotkey recorder for pause/resume the speech display");
		self.skipNoteLabel = NSLocalizedStringFromTableInBundle(@"Skip Note", @"Localizable", bundle, @"Label for hotkey recorder for skipping the current note");
		self.clickNoteLabel = NSLocalizedStringFromTableInBundle(@"Click Note", @"Localizable", bundle, @"Label for hotkey recorder for 'clicking' the current note being spoken");
	}
   return self;
}


- (NSString *) mainNibName {
	return @"GrowlSpeechPrefs";
}

- (NSSet*)bindingKeys {
	static NSSet *keys = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keys = [NSSet setWithObjects:@"useLimit",
					@"characterLimit",
					@"useRate",
					@"rate",
					@"useVolume",
					@"volume", nil];
	});
	return keys;
}

- (void) awakeFromNib {
	[self updateVoiceList];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSInteger pauseCode = [[defaults valueForKey:GrowlSpeechPauseKeyCodePref] integerValue];
	NSUInteger pauseModifiers = [[defaults valueForKey:GrowlSpeechPauseKeyModifierPref] unsignedIntegerValue];
	KeyCombo pauseCombo = {SRCarbonToCocoaFlags(pauseModifiers), pauseCode};
	(self.pauseShortcut).keyCombo = pauseCombo;
	
	NSInteger skipCode = [[defaults valueForKey:GrowlSpeechSkipKeyCodePref] integerValue];
	NSUInteger skipModifiers = [[defaults valueForKey:GrowlSpeechSkipKeyModifierPref] unsignedIntegerValue];
	KeyCombo skipCombo = {SRCarbonToCocoaFlags(skipModifiers), skipCode};
	(self.skipShortcut).keyCombo = skipCombo;
	
	NSInteger clickCode = [[defaults valueForKey:GrowlSpeechClickKeyCodePref] integerValue];
	NSUInteger clickModifiers = [[defaults valueForKey:GrowlSpeechClickKeyModifierPref] unsignedIntegerValue];
	KeyCombo clickCombo = {SRCarbonToCocoaFlags(clickModifiers), clickCode};
	(self.clickShortcut).keyCombo = clickCombo;
}

-(void)updateVoiceList {
	NSMutableArray *voiceAttributes = [NSMutableArray array];
	
	NSMutableDictionary *defaultChoice = [NSMutableDictionary dictionary];
	defaultChoice[NSVoiceIdentifier] = GrowlSpeechSystemVoice;
	defaultChoice[NSVoiceName] = NSLocalizedString(@"System Default", @"The voice chosen as the system voice in the Speech preference pane");
	[voiceAttributes addObject:defaultChoice];
	
	for (NSString *voiceIdentifier in [NSSpeechSynthesizer availableVoices]) {
		[voiceAttributes addObject:[NSSpeechSynthesizer attributesForVoice:voiceIdentifier]];
	}
	self.voices = voiceAttributes;
}

-(void)updateConfigurationValues {
	[self updateVoiceList];
	NSString *voice = [self.configuration valueForKey:GrowlSpeechVoicePref];
	NSArray *availableVoices = [voices valueForKey:NSVoiceIdentifier];
	NSUInteger row = NSNotFound;
	if (voice) {
		row = [availableVoices indexOfObject:voice];
	}
	
	if (row == NSNotFound)
		row = [availableVoices indexOfObject:[NSSpeechSynthesizer defaultVoice]];
	
	if ((row == NSNotFound) && (availableVoices.count))
		row = 1;
	
	if (row != NSNotFound && voices.count > 0) {
		[voiceList selectItemAtIndex:row];
	}
	[super updateConfigurationValues];
}

- (IBAction) previewVoice:(id)sender {
	NSInteger row = [sender indexOfSelectedItem];
	
	if (row != -1) {
		if(lastPreview != nil && lastPreview.speaking) {
			[lastPreview stopSpeaking];
		}
		NSString *voice = voices[row][NSVoiceIdentifier];
		if([voice isEqualToString:GrowlSpeechSystemVoice])
            voice = nil;
        NSSpeechSynthesizer *quickVoice = [[NSSpeechSynthesizer alloc] initWithVoice:voice];
		[quickVoice startSpeakingString:[NSString stringWithFormat:NSLocalizedString(@"This is a preview of the %@ voice.", nil), voices[row][NSVoiceName]]];
		lastPreview = quickVoice;
	}
}

- (IBAction) voiceClicked:(id)sender {
	NSInteger row = [sender indexOfSelectedItem];

	if (row != -1) {
		NSString *voice = voices[row][NSVoiceIdentifier];
		[self setConfigurationValue:voice forKey:GrowlSpeechVoicePref];
		[self previewVoice:sender];
	}
}

#pragma mark -
#pragma mark Accessors

-(BOOL)useLimit {
	BOOL value = GrowlSpeechUseLimitDefault;
	if([self.configuration valueForKey:GrowlSpeechUseLimitPref]){
		value = [[self.configuration valueForKey:GrowlSpeechUseLimitPref] boolValue];
	}
	return value;
}
-(void)setUseLimit:(BOOL)value {
	[self setConfigurationValue:@(value) forKey:GrowlSpeechUseLimitPref];
}

-(BOOL)useRate {
	BOOL value = GrowlSpeechUseRateDefault;
	if([self.configuration valueForKey:GrowlSpeechUseRatePref]){
		value = [[self.configuration valueForKey:GrowlSpeechUseRatePref] boolValue];
	}
	return value;
}
-(void)setUseRate:(BOOL)value {
	[self setConfigurationValue:@(value) forKey:GrowlSpeechUseRatePref];
}

-(BOOL)useVolume {
	BOOL value = GrowlSpeechUseVolumeDefault;
	if([self.configuration valueForKey:GrowlSpeechUseVolumePref]){
		value = [[self.configuration valueForKey:GrowlSpeechUseVolumePref] boolValue];
	}
	return value;
}
-(void)setUseVolume:(BOOL)value {
	[self setConfigurationValue:@(value) forKey:GrowlSpeechUseVolumePref];
}

-(NSUInteger)characterLimit {
	NSUInteger value = GrowlSpeechLimitDefault;
	if([self.configuration valueForKey:GrowlSpeechLimitPref]){
		value = [[self.configuration valueForKey:GrowlSpeechLimitPref] unsignedIntegerValue];
	}
	return value;
}
-(void)setCharacterLimit:(NSUInteger)value {
	[self setConfigurationValue:@(value) forKey:GrowlSpeechLimitPref];
}

-(float)rate {
	float value = GrowlSpeechRateDefault;
	if([self.configuration valueForKey:GrowlSpeechRatePref]){
		value = [[self.configuration valueForKey:GrowlSpeechRatePref] floatValue];
	}
	return value;
}
-(void)setRate:(float)value {
	[self setConfigurationValue:@(value) forKey:GrowlSpeechRatePref];
}

-(NSUInteger)volume {
	NSUInteger value = GrowlSpeechVolumeDefault;
	if([self.configuration valueForKey:GrowlSpeechVolumePref]){
		value = [[self.configuration valueForKey:GrowlSpeechVolumePref] unsignedIntegerValue];
	}
	return value;
}
-(void)setVolume:(NSUInteger)value {
	[self setConfigurationValue:@(value) forKey:GrowlSpeechVolumePref];
}

#pragma mark SRRecorderControl delegate

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason
{
	return NO;
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{
	SGKeyCombo *combo = [SGKeyCombo keyComboWithKeyCode:newKeyCombo.code modifiers:SRCocoaToCarbonFlags(newKeyCombo.flags)];
	
	if(combo.keyCode == -1)
		combo = nil;
	
	SpeechHotKey type = SpeechPauseHotKey;
	NSString *codePref = GrowlSpeechPauseKeyCodePref;
	NSString *modifierPref = GrowlSpeechPauseKeyModifierPref;
	if(aRecorder == skipShortcut){
		type = SpeechSkipHotKey;
		codePref = GrowlSpeechSkipKeyCodePref;
		modifierPref = GrowlSpeechSkipKeyModifierPref;
	}
	if(aRecorder == clickShortcut){
		type = SpeechClickHotKey;
		codePref = GrowlSpeechClickKeyCodePref;
		modifierPref = GrowlSpeechClickKeyModifierPref;
	}
	
    if(combo)
    {
        [[NSUserDefaults standardUserDefaults] setObject:@(combo.keyCode)
                                                  forKey:codePref];
        [[NSUserDefaults standardUserDefaults] setObject:@(combo.modifiers)
                                                  forKey:modifierPref];
        [[NSUserDefaults standardUserDefaults] synchronize];
	}
    else
    {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:codePref];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:modifierPref];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
	[[NSNotificationCenter defaultCenter] postNotificationName:GrowlSpeechHotKeyChanged
																		 object:self 
																	  userInfo:@{@"hotKeyType": @(type)}];
}

@end
