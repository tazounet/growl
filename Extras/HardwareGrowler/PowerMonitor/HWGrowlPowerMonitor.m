//
//  HWGrowlPowerMonitor.m
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/6/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "HWGrowlPowerMonitor.h"
#include <IOKit/IOKitLib.h>
#include <IOKit/ps/IOPSKeys.h>
#include <IOKit/ps/IOPowerSources.h>

@interface HWGrowlPowerMonitor ()

+(NSInteger)batteryPercentageForPowerSourceDescription:(CFDictionaryRef)description;

@end

@interface GrowlPowerSourceDescription : NSObject

@property (nonatomic, assign) BOOL charging;
@property (nonatomic, assign) BOOL charged;
@property (nonatomic, assign) BOOL finishingCharge;
@property (nonatomic, assign) NSInteger percentage;
@property (nonatomic, assign) HGPowerSource powerType;
@property (nonatomic, assign) NSInteger remainingTime;

@property (nonatomic, strong) NSString *typeString;

-(instancetype)init NS_UNAVAILABLE;
-(instancetype)initWithPowerSourceDescription:(CFDictionaryRef)description NS_DESIGNATED_INITIALIZER;

@end

@implementation GrowlPowerSourceDescription

+(GrowlPowerSourceDescription*)descriptionWithDescription:(CFDictionaryRef)description {
	return [[GrowlPowerSourceDescription alloc] initWithPowerSourceDescription:description];
}

-(instancetype)initWithPowerSourceDescription:(CFDictionaryRef)description {
	if((self = [super init])){
		CFStringRef powerType = CFDictionaryGetValue(description, CFSTR(kIOPSTransportTypeKey));
		if (CFStringCompare(powerType, CFSTR(kIOPSInternalType), 0) == kCFCompareEqualTo)
		{
			_powerType = HGBatteryPower;
			self.typeString = NSLocalizedString(@"Battery", @"Internal battery");
		}
		else if (CFStringCompare(powerType, CFSTR(kIOPSSerialTransportType), 0) == kCFCompareEqualTo ||
					CFStringCompare(powerType, CFSTR(kIOPSUSBTransportType), 0) == kCFCompareEqualTo ||
					CFStringCompare(powerType, CFSTR(kIOPSNetworkTransportType), 0) == kCFCompareEqualTo )
		{
			_powerType = HGUPSPower;
			self.typeString = NSLocalizedString(@"UPS", @"Uninteruptable Power supply");
		}
		else
		{
			_powerType = HGUnknownPower;
			self.typeString = NSLocalizedString(@"Unknown", @"Unknown power supply type");
		}
		
		if (CFDictionaryGetValue(description, CFSTR(kIOPSIsChargingKey)) == kCFBooleanTrue)
			_charging = YES;
		else
			_charging = NO;
		
		if (CFDictionaryGetValue(description, CFSTR(kIOPSIsChargedKey)) == kCFBooleanTrue)
			_charged = YES;
		else
			_charged = NO;
		
		CFTypeRef finishingValue = CFDictionaryGetValue(description, CFSTR(kIOPSIsFinishingChargeKey));
		if(finishingValue && finishingValue == kCFBooleanTrue)
			_finishingCharge = YES;
		else
			_finishingCharge = NO;
		
		_percentage = [HWGrowlPowerMonitor batteryPercentageForPowerSourceDescription:description];

		CFNumberRef timeToFullOrEmpty = NULL;
		if(_charging){
			timeToFullOrEmpty = CFDictionaryGetValue(description, CFSTR(kIOPSTimeToFullChargeKey));
		}else if(!_charging){ 
			timeToFullOrEmpty = CFDictionaryGetValue(description, CFSTR(kIOPSTimeToEmptyKey));
		}
		
		if(timeToFullOrEmpty){
			int64_t timeToChargeOrDrain;
			int64_t batteryTime = -1;
						
			if(CFNumberGetType(timeToFullOrEmpty) != kCFNumberSInt64Type)
				NSLog(@"GAH");
			
			if (CFNumberGetValue(timeToFullOrEmpty, kCFNumberSInt64Type, &timeToChargeOrDrain))
				batteryTime = timeToChargeOrDrain;
			
			if(batteryTime >= 0.0)
				_remainingTime = (NSInteger)batteryTime;
			else
				_remainingTime = kIOPSTimeRemainingUnknown;
		}else{
			_remainingTime = kIOPSTimeRemainingUnknown;
		}
	}
	return self;
}


-(NSString*)notificationDescriptionForCurrentSource:(HGPowerSource)currentSource {
	NSMutableString *description = nil;
	
	NSString *state = nil;
	NSString *time = nil;
	NSString *percentage = nil;
	
	if(_charging)
		state = NSLocalizedString(@"Charging", @"");
	else if(_finishingCharge)
		state = NSLocalizedString(@"Finishing", @"");
	else if (_charged)
		state = NSLocalizedString(@"Charged", @"");
	
	if(_percentage >= 0.0)
		percentage = [NSString stringWithFormat:@"%ld%%", _percentage];
	
	if(_remainingTime > 0.0){
		NSString *format = (currentSource == HGACPower) ? NSLocalizedString(@"Time to charge: %ld minutes", @"") : NSLocalizedString(@"Time remaining: %ld minutes", @"");
		time = [NSString stringWithFormat:format, _remainingTime];
	}
	
	if(state || time || percentage){
		description = [NSMutableString string];
		
		[description appendFormat:@"%@: ", self.typeString];
		if(state){
			[description appendFormat:@"%@", state];
			if(percentage)
				[description appendString:@" "];
			else if(time)
				[description appendString:@"\n"];
		}
		if(percentage){
			[description appendFormat:NSLocalizedString(@"at %@", @"at battery percentage"), percentage];
			if(time)
				[description appendString:@"\n"];
		}
		if(time){
			[description appendFormat:@"%@", time];
		}
	}
	return description;
}

@end

@interface HWGrowlPowerMonitor ()

@property (nonatomic, unsafe_unretained) id<HWGrowlPluginControllerProtocol> delegate;
@property (nonatomic, assign)	CFRunLoopSourceRef notificationRunLoopSource;

@property (nonatomic, assign) HGPowerSource lastPowerSource;
@property (nonatomic, assign) NSTimeInterval lastKnownTime;

@property (nonatomic, strong) NSTimer *refireTimer;
@property (nonatomic, assign) BOOL lastWarnState;

@property (nonatomic, strong) NSString *refireBatteryStatusLabel;
@property (nonatomic, strong) NSString *refireEveryLabel;
@property (nonatomic, strong) NSString *minutesLabel;
@property (nonatomic, strong) NSString *refireOnlyOnBatteryLabel;

@end

@implementation HWGrowlPowerMonitor

@synthesize prefsView;
@synthesize delegate;
@synthesize notificationRunLoopSource;
@synthesize lastPowerSource;
@synthesize lastKnownTime;
@synthesize refireTimer;
@synthesize lastWarnState;

-(instancetype)init {
	if((self = [super init])){
		self.notificationRunLoopSource = IOPSNotificationCreateRunLoopSource(powerSourceChanged, (__bridge void *)(self));
		
		if (notificationRunLoopSource)
			CFRunLoopAddSource(CFRunLoopGetCurrent(), notificationRunLoopSource, kCFRunLoopDefaultMode);
		lastPowerSource = HGUnknownPower;
		lastKnownTime = kIOPSTimeRemainingUnknown;
		lastWarnState = NO;
		
		self.refireBatteryStatusLabel = NSLocalizedString(@"Refire battery status", @"Label for checkbox that sets battery status to redisplay every so often");
		self.refireEveryLabel = NSLocalizedString(@"Refire every:", @"Label for box for putting in the amount of time between refire");
		self.minutesLabel = NSLocalizedString(@"minutes", @"Unit label for how often to refire the battery status");
		self.refireOnlyOnBatteryLabel = NSLocalizedString(@"Refire only on battery", @"Label for checkbox that sets whether to only show battery status every x minutes when on battery pwoer");
	}
	return self;
}

-(void)dealloc {
	CFRunLoopRemoveSource(CFRunLoopGetCurrent(), notificationRunLoopSource, kCFRunLoopDefaultMode);
	CFRelease(notificationRunLoopSource);
	[refireTimer invalidate];
	
	
	
	
    
}

-(void)fireOnLaunchNotes {
	[self powerSourceChanged:YES];
	[self checkTimer];
}

-(BOOL)refireOnBattery {
	BOOL result = YES;
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"RefireOnBattery"])
		result = [[NSUserDefaults standardUserDefaults] boolForKey:@"RefireOnBattery"];
	return result;
}
-(void)setRefireOnBattery:(BOOL)refire {
	[[NSUserDefaults standardUserDefaults] setBool:refire forKey:@"RefireOnBattery"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self checkTimer];
}

-(CGFloat)refireTime {
	CGFloat result = 10.0f;
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"PowerRefireTime"])
		result = [[NSUserDefaults standardUserDefaults] floatForKey:@"PowerRefireTime"];
	return result;
}
-(void)setRefireTime:(CGFloat)time {
	[[NSUserDefaults standardUserDefaults] setFloat:time forKey:@"PowerRefireTime"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self stopTimer];
	[self checkTimer];
}

-(BOOL)enableRefire {
	BOOL result = YES;
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"EnablePowerRefire"])
		result = [[NSUserDefaults standardUserDefaults] boolForKey:@"EnablePowerRefire"];
	return result;
}
-(void)setEnableRefire:(BOOL)enable {
	[[NSUserDefaults standardUserDefaults] setBool:enable forKey:@"EnablePowerRefire"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self checkTimer];
}

-(void)checkTimer {
	if(refireTimer) {
		/* Conditions under which we stop:
		 * refire is disabled, or we are on AC and we only want to fire on battery
		 */
		if(![self enableRefire] || (lastPowerSource == HGACPower && [self refireOnBattery]))
			[self stopTimer];
	} else {
		/* Conditions under which we start:
		 * refire is enabled, and we are not on AC or we only want to fire on battery
		 */
		if([self enableRefire] && (lastPowerSource != HGACPower || ![self refireOnBattery]))
			[self startTimer];
	}
}

-(void)startTimer {	
	if(refireTimer)
		return;
	
//	NSLog(@"start timer");
	self.refireTimer = [NSTimer timerWithTimeInterval:[self refireTime] * 60.0f
															 target:self 
														  selector:@selector(timerFire:)
														  userInfo:nil
															repeats:YES];
	[[NSRunLoop mainRunLoop] addTimer:refireTimer forMode:NSDefaultRunLoopMode];
    [[NSRunLoop mainRunLoop] addTimer:refireTimer forMode:NSEventTrackingRunLoopMode];
    [[NSRunLoop mainRunLoop] addTimer:refireTimer forMode:NSModalPanelRunLoopMode];
}

-(void)stopTimer {
	if(!refireTimer)
		return;
	
//	NSLog(@"stop timer");
	[refireTimer invalidate];
	self.refireTimer = nil;
}

-(void)timerFire:(NSTimer*)timer {
	[self powerSourceChanged:YES];
}

-(void)powerSourceChanged:(BOOL)force {
	BOOL changedType = NO;
	BOOL hasBattery = NO;
	BOOL chargingOrFinishing = NO;
	NSInteger percentage = -1;
	
	CFTypeRef sourcesBlob = IOPSCopyPowerSourcesInfo();
	if(sourcesBlob)
	{
		NSString *source = (__bridge NSString*)IOPSGetProvidingPowerSourceType(sourcesBlob);
		
		HGPowerSource currentSource;
		if([source compare:@"AC Power"] == NSOrderedSame) {
			currentSource = HGACPower;
		} else if ([source compare:@"Battery Power"] == NSOrderedSame) {
			currentSource = HGBatteryPower;
		} else if ([source compare:@"UPS Power"] == NSOrderedSame) {
			currentSource = HGUPSPower;
		} else {
			currentSource = HGUnknownPower;
		}
		
		if(currentSource != lastPowerSource)
			changedType = YES;
		
		NSMutableArray *powerSourceDescriptions = [NSMutableArray array];
		CFArrayRef	powerSourcesList = IOPSCopyPowerSourcesList(sourcesBlob);
		if(powerSourcesList)
		{
			CFIndex	count = CFArrayGetCount(powerSourcesList);
			for (CFIndex i = 0; i < count; ++i) {
				CFTypeRef		powerSource;
				CFDictionaryRef description;
				
				powerSource = CFArrayGetValueAtIndex(powerSourcesList, i);
				description = IOPSGetPowerSourceDescription(sourcesBlob, powerSource);
				
				if(!description)
					continue;
				
				hasBattery = YES;
				GrowlPowerSourceDescription *growlDescription = [GrowlPowerSourceDescription descriptionWithDescription:description];
				[powerSourceDescriptions addObject:growlDescription];
				
				if(growlDescription.charging || growlDescription.finishingCharge)
					chargingOrFinishing = YES;
				
				if(growlDescription.percentage > percentage)
					percentage = growlDescription.percentage;
			}
			CFRelease(powerSourcesList);
		}
		
		__block CFTimeInterval remaining = kIOPSTimeRemainingUnknown;
		if(currentSource == HGACPower){
			//enumerate them and find greatest
			[powerSourceDescriptions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				if([obj remainingTime] > remaining)
					remaining = [obj remainingTime];
			}];
		}else if(currentSource == HGUPSPower || currentSource == HGBatteryPower){
			remaining = IOPSGetTimeRemainingEstimate();
			if(remaining >= 0.0f)
				remaining /= 60.0f;
		}
		

		BOOL sendTime = NO;
		if(remaining != kIOPSTimeRemainingUnknown && (changedType || (remaining == kIOPSTimeRemainingUnknown) != (lastKnownTime == kIOPSTimeRemainingUnknown)))
			sendTime = YES;
				
		BOOL warnBattery = NO;
		IOPSLowBatteryWarningLevel warnLevel = IOPSGetBatteryWarningLevel();
		if(warnLevel != kIOPSLowBatteryWarningNone)
			warnBattery = YES;
		
		if(lastWarnState && warnBattery)
			warnBattery = NO;
		else if(!lastWarnState && warnBattery)
			lastWarnState = YES;
		else if(lastWarnState && !warnBattery)
			lastWarnState = NO;
		
		if(changedType || sendTime || warnBattery || force){
			NSString *title = nil;
			NSString *name = nil;
			NSString *localizedSource = [self localizedNameForSource:currentSource];
			NSString *description = nil;
			NSString *powerDescription = [self chargingDescriptionForPowerSources:powerSourceDescriptions
																					  currentSource:currentSource];
			if(!warnBattery){
				name = @"PowerChange";
				title = [NSString stringWithFormat:NSLocalizedString(@"On %@", @"Format string for On <power type>"), localizedSource];
				description = hasBattery ? powerDescription : @"";
			} else {
				name = @"PowerWarning";
				title	= NSLocalizedString(@"Battery Low!", @"");
				description = NSLocalizedString(@"Battery Low, Please plug the computer in now", @"");
				if(powerDescription)
					description = [description stringByAppendingFormat:@"\n%@", powerDescription];
			}
			
			if(!description)
				description = [NSMutableString string];
						
			NSString *imageName = nil;
			switch (currentSource) {
				case HGACPower:
					if(chargingOrFinishing)
						imageName = @"Power-Charging";
					else
						imageName = @"Power-Plugged";
					break;
				case HGBatteryPower:
				case HGUPSPower:
					if(percentage >= 0){
						CGFloat adjusted = roundf((CGFloat)percentage / 10.0f);
						imageName = [NSString stringWithFormat:@"Power-%ld0", (NSInteger)adjusted];
						if(adjusted == 0)
							imageName = @"Power-0";
					}
					else
					{
						imageName = @"Power-NoBattery";
					}
					break;
				case HGUnknownPower:
				default:
					//Shouldn't get to either of these
					imageName = @"Power-BatteryFailure";
					break;
			}
			
			@autoreleasepool
			{
				NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:@"tif"];
            NSData *iconData = [NSData dataWithContentsOfFile:imagePath];
            
            [delegate notifyWithName:name
                               title:title
								 description:description
                                icon:iconData
                    identifierString:name
                       contextString:nil
                              plugin:self];
			}
			lastPowerSource = currentSource;
			lastKnownTime = remaining;
		}
		
		CFRelease(sourcesBlob);
	}
}

-(NSMutableString*)chargingDescriptionForPowerSources:(NSArray*)sources currentSource:(HGPowerSource)currentSource {
	__block NSMutableString *description = nil;
	[sources enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {		
		NSString *sourceString = [obj notificationDescriptionForCurrentSource:currentSource];
		if(sourceString){
			if(!description)
				description = [NSMutableString string];
			else
				[description appendString:@"\n"];
			[description appendString:sourceString];
		}
	}];
	return description;
}

+(NSInteger)batteryPercentageForPowerSourceDescription:(CFDictionaryRef)description {
	NSInteger percentageCapacity = -1;
	
	if(description && CFDictionaryGetValue(description, CFSTR(kIOPSIsPresentKey)) == kCFBooleanTrue){		
		CFNumberRef currentCapacityNum = CFDictionaryGetValue(description, CFSTR(kIOPSCurrentCapacityKey));
		CFNumberRef maxCapacityNum = CFDictionaryGetValue(description, CFSTR(kIOPSMaxCapacityKey));
		
		CFIndex currentCapacity, maxCapacity, sourceCapacity = -1;
		
		if (CFNumberGetValue(currentCapacityNum, kCFNumberCFIndexType, &currentCapacity) &&
			 CFNumberGetValue(maxCapacityNum, kCFNumberCFIndexType, &maxCapacity))
			sourceCapacity = roundf((currentCapacity / (float)maxCapacity) * 100.0f);
		
		if(sourceCapacity > percentageCapacity)
			percentageCapacity = sourceCapacity;
	}
	
	return percentageCapacity;
}

-(NSString*)localizedNameForSource:(HGPowerSource)source {
	NSString *result = nil;
	switch (source) {
		case HGACPower:
			result = NSLocalizedString(@"AC Power", @"");
			break;
		case HGBatteryPower:
			result = NSLocalizedString(@"Battery Power", @"");
			break;
		case HGUPSPower:
			result = NSLocalizedString(@"UPS Power", @"");
			break;
		case HGUnknownPower:
		default:
			result = NSLocalizedString(@"Unknown Power Source", @"");
			break;
	}
	return result;
}

static void powerSourceChanged(void *context) {
	HWGrowlPowerMonitor *monitor = (__bridge HWGrowlPowerMonitor*)context;
	[monitor powerSourceChanged:NO];
	[monitor checkTimer];
}

#pragma mark HWGrowlPluginProtocol

-(void)setDelegate:(id<HWGrowlPluginControllerProtocol>)aDelegate{
	delegate = aDelegate;
}
-(id<HWGrowlPluginControllerProtocol>)delegate {
	return delegate;
}
-(NSString*)pluginDisplayName {
	return NSLocalizedString(@"Power Monitor", @"");
}
-(NSImage*)preferenceIcon {
	static NSImage *_icon = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_icon = [NSImage imageNamed:@"HWGPrefsPower"];
	});
	return _icon;
}
-(NSView*)preferencePane {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        [bundle loadNibNamed:@"PowerMonitorPrefs" owner:self topLevelObjects:nil];
	});
	return prefsView;
}

#pragma mark HWGrowlPluginNotifierProtocol

-(NSArray*)noteNames {
	return @[@"PowerChange", @"PowerWarning"];
}
-(NSDictionary*)localizedNames {
	return @{@"PowerChange": NSLocalizedString(@"Power Changed", @""),
			  @"PowerWarning": NSLocalizedString(@"Power Warning", @"")};
}
-(NSDictionary*)noteDescriptions {
	return @{@"PowerChange": NSLocalizedString(@"Sent when the type or status of power changed", @""),
			  @"PowerWarning": NSLocalizedString(@"Sent when the battery is getting low", @"")};
}
-(NSArray*)defaultNotifications {
	return @[@"PowerChange", @"PowerWarning"];
}

@end
