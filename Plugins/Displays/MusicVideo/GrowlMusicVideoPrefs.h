//
//  GrowlMusicVideoPrefs.h
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 14/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import <GrowlPlugins/GrowlPluginPreferencePane.h>

#define GrowlMusicVideoPrefDomain			@"com.Growl.MusicVideo"

#define MUSICVIDEO_SCREEN_PREF			@"Screen"

#define MUSICVIDEO_OPACITY_PREF			@"Opacity"
#define MUSICVIDEO_DEFAULT_OPACITY		60.0

#define MUSICVIDEO_DURATION_PREF		@"Duration"
#define GrowlMusicVideoDurationPrefDefault		5.0

#define MUSICVIDEO_SIZE_PREF			@"Size"
typedef NS_ENUM(NSInteger, MusicVideoSize) {
	MUSICVIDEO_SIZE_NORMAL = 0,
	MUSICVIDEO_SIZE_HUGE = 1
};

#define MUSICVIDEO_EFFECT_PREF			@"Transition effect"
typedef NS_ENUM(NSInteger, MusicVideoEffectType) {
	MUSICVIDEO_EFFECT_SLIDE	= 0,
	MUSICVIDEO_EFFECT_WIPE = 1,
	MUSICVIDEO_EFFECT_FADING = 2
};

#define MUSICVIDEO_TEXT_ALIGN_PREF		@"Text Alignment"

#define GrowlMusicVideoVeryLowBackgroundColor	@"MusicVideo-Priority-VeryLow-Color"
#define GrowlMusicVideoModerateBackgroundColor	@"MusicVideo-Priority-Moderate-Color"
#define GrowlMusicVideoNormalBackgroundColor	@"MusicVideo-Priority-Normal-Color"
#define GrowlMusicVideoHighBackgroundColor		@"MusicVideo-Priority-High-Color"
#define GrowlMusicVideoEmergencyBackgroundColor	@"MusicVideo-Priority-Emergency-Color"

#define GrowlMusicVideoVeryLowTextColor			@"MusicVideo-Priority-VeryLow-Text-Color"
#define GrowlMusicVideoModerateTextColor		@"MusicVideo-Priority-Moderate-Text-Color"
#define GrowlMusicVideoNormalTextColor			@"MusicVideo-Priority-Normal-Text-Color"
#define GrowlMusicVideoHighTextColor			@"MusicVideo-Priority-High-Text-Color"
#define GrowlMusicVideoEmergencyTextColor		@"MusicVideo-Priority-Emergency-Text-Color"

@interface GrowlMusicVideoPrefs : GrowlPluginPreferencePane {
	IBOutlet NSSlider *slider_opacity;
}

- (CGFloat) duration;
- (void) setDuration:(CGFloat)value;
- (unsigned) effect;
- (void) setEffect:(unsigned)newEffect;
- (CGFloat) opacity;
- (void) setOpacity:(CGFloat)value;
- (int) size;
- (void) setSize:(int)value;
- (int) screen;
- (void) setScreen:(int)value;

@property (nonatomic, assign) NSInteger textAlignment;

- (NSColor *) textColorVeryLow;
- (void) setTextColorVeryLow:(NSColor *)value;
- (NSColor *) textColorModerate;
- (void) setTextColorModerate:(NSColor *)value;
- (NSColor *) textColorNormal;
- (void) setTextColorNormal:(NSColor *)value;
- (NSColor *) textColorHigh;
- (void) setTextColorHigh:(NSColor *)value;
- (NSColor *) textColorEmergency;
- (void) setTextColorEmergency:(NSColor *)value;

- (NSColor *) backgroundColorVeryLow;
- (void) setBackgroundColorVeryLow:(NSColor *)value;
- (NSColor *) backgroundColorModerate;
- (void) setBackgroundColorModerate:(NSColor *)value;
- (NSColor *) backgroundColorNormal;
- (void) setBackgroundColorNormal:(NSColor *)value;
- (NSColor *) backgroundColorHigh;
- (void) setBackgroundColorHigh:(NSColor *)value;
- (NSColor *) backgroundColorEmergency;
- (void) setBackgroundColorEmergency:(NSColor *)value;

@end
