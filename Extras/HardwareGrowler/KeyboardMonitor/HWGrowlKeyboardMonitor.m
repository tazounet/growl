//
//  HWGrowlKeyboardMonitor.m
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/29/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "HWGrowlKeyboardMonitor.h"

@interface HWGrowlKeyboardMonitor ()

@property (nonatomic, unsafe_unretained) id<HWGrowlPluginControllerProtocol> delegate;
@property (nonatomic, strong) IBOutlet NSView *prefsView;

@property (nonatomic, strong) NSString *notifyForLabel;
@property (nonatomic, strong) NSString *capsLockLabel;
@property (nonatomic, strong) NSString *fnKeyLabel;
@property (nonatomic, strong) NSString *shifyKeyLabel;

@property (nonatomic) BOOL capsFlag;
@property (nonatomic) BOOL fnFlag;
@property (nonatomic) BOOL shiftFlag;

@end

@implementation HWGrowlKeyboardMonitor

@synthesize delegate;
@synthesize prefsView;

@synthesize notifyForLabel;
@synthesize capsLockLabel;
@synthesize fnKeyLabel;
@synthesize shifyKeyLabel;

@synthesize capsFlag;
@synthesize fnFlag;
@synthesize shiftFlag;

-(instancetype)init {
	if((self = [super init])){
        
		//Bleh, not happy with this really, but eh
		NSDictionary *enabledDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"hwgkeyboardkeysenabled"];
		if(!enabledDict){
			//Our default keys are caps, with fn and shift being disabled by default
			NSDictionary *defaultKeys = @{@"capslock": @YES,
												  @"fnkey": @NO,
												  @"shiftkey": @NO};
			[[NSUserDefaults standardUserDefaults] setObject:defaultKeys 
																	forKey:@"hwgkeyboardkeysenabled"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
		
		self.notifyForLabel = NSLocalizedString(@"Notify For:", @"Label over list of checkboxes for notifying for certain keys");
		self.capsLockLabel = NSLocalizedString(@"Caps Lock", @"");
		self.fnKeyLabel = NSLocalizedString(@"FN Key", @"");
		self.shifyKeyLabel = NSLocalizedString(@"Shift Key", @"");
	}
	return self;
}


-(void)postRegistrationInit {
	[self initFlags];
	[self listen];
}

-(void) listen
{
	
	NSEvent* (^myHandler)(NSEvent*) = ^(NSEvent* event)
	{
		//		NSLog(@"flags changed");
#define CHECK_FLAG(NAME)	if(self.NAME ## Flag != NAME)\
[self sendNotification:NAME forFlag:@"" #NAME];\
self.NAME ## Flag = NAME;
		
		NSUInteger flags = [NSEvent modifierFlags];
		BOOL caps = flags & NSEventModifierFlagCapsLock ? YES : NO;
		BOOL fn = flags & NSEventModifierFlagFunction ? YES : NO;
		BOOL shift = flags & NSEventModifierFlagShift ? YES : NO;
		
		CHECK_FLAG(caps);
		CHECK_FLAG(fn);
		CHECK_FLAG(shift)
		
		return event;
	};
	
	[NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged 
													  handler:myHandler];
	[NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged 
														handler: ^(NSEvent* event)
	 {
		 myHandler(event);
	 }];
	
}

- (void)sendNotification:(BOOL)newState forFlag:(NSString*)type
{
	NSString *name = nil;
	NSString *title = nil;
	NSString *identifier = nil;
	NSString *imageName = nil;
	
	NSString *enabledKey = nil;

	if([type isEqualToString:@"caps"]){
		enabledKey = @"capslock";
		name = newState ? @"CapsLockOn" : @"CapsLockOff";
		title = newState ? NSLocalizedString(@"Caps Lock On", @"") : NSLocalizedString(@"Caps Lock Off", @"");
		identifier = @"HWGrowlCaps";
		imageName = newState ? @"Capster-CapsLock-On" : @"Capster-CapsLock-Off";
	}else if ([type isEqualToString:@"fn"]){
		enabledKey = @"fnkey";
		name = newState ? @"FNPressed" : @"FNReleased";
		title = newState ? NSLocalizedString(@"FN Key Pressed", @"") : NSLocalizedString(@"FN Key Released", @"");
		identifier = @"HWGrowlFNKey";
		imageName = newState ? @"Capster-FnKey-On" : @"Capster-FnKey-Off";
	}else if ([type isEqualToString:@"shift"]){
		enabledKey = @"shiftkey";
		name = newState ? @"ShiftPressed" : @"ShiftReleased";
		title = newState ? NSLocalizedString(@"Shift Key Pressed", @"") : NSLocalizedString(@"Shift Key Released", @"");
		identifier = @"HWGrowlShiftKey";
		imageName = newState ? @"Capster-Shift-On" : @"Capster-Shift-Off";
	}else {
		return;
	}
	
	//Check that we are enabled in the keyboard monitor's preferences
	NSNumber *enabled = [[NSUserDefaultsController sharedUserDefaultsController].values valueForKeyPath:[NSString stringWithFormat:@"hwgkeyboardkeysenabled.%@", enabledKey]];
	if(!enabled.boolValue)
		return;

    @autoreleasepool
    {
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:@"tif"];
    NSData *iconData = [NSData dataWithContentsOfFile:imagePath];
    [delegate notifyWithName:name
                       title:title
                 description:nil
                        icon:iconData
            identifierString:identifier
               contextString:nil
                      plugin:self];
    }
}

-(void) initFlags
{
	NSUInteger flags = [NSEvent modifierFlags];
	capsFlag = flags & NSEventModifierFlagCapsLock ? YES : NO;
	fnFlag = flags & NSEventModifierFlagFunction ? YES : NO;
	shiftFlag = flags & NSEventModifierFlagShift ? YES : NO;
}

#pragma mark HWGrowlPluginProtocol

-(void)setDelegate:(id<HWGrowlPluginControllerProtocol>)aDelegate{
	delegate = aDelegate;
}
-(id<HWGrowlPluginControllerProtocol>)delegate {
	return delegate;
}
-(NSString*)pluginDisplayName{
	return NSLocalizedString(@"Keyboard Monitor", @"");
}
-(NSImage*)preferenceIcon {
	static NSImage *_icon = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_icon = [NSImage imageNamed:@"HWGPrefsCapster"];
	});
	return _icon;
}
-(NSView*)preferencePane {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        [bundle loadNibNamed:@"KeyboardMonitorPrefs" owner:self topLevelObjects:nil];
	});
	return prefsView;
}
-(BOOL)enabledByDefault {
	return NO;
}

#pragma mark HWGrowlPluginNotifierProtocol

-(NSArray*)noteNames {
	return @[@"CapsLockOn", @"CapsLockOff", @"FNPressed", @"FNReleased", @"ShiftPressed", @"ShiftReleased"];
}
-(NSDictionary*)localizedNames {
	return @{@"CapsLockOn": NSLocalizedString(@"Caps Lock On", @""),
			  @"CapsLockOff": NSLocalizedString(@"Caps Lock Off", @""),
			  @"FNPressed": NSLocalizedString(@"FN Key Pressed", @""),
			  @"FNReleased": NSLocalizedString(@"FN Key Released", @""),
			  @"ShiftPressed": NSLocalizedString(@"Shift Key Pressed", @""),
			  @"ShiftReleased": NSLocalizedString(@"Shift Key Released", @"")};
}
-(NSDictionary*)noteDescriptions {
	return @{@"CapsLockOn": NSLocalizedString(@"Caps Lock On", @""),
			  @"CapsLockOff": NSLocalizedString(@"Caps Lock Off", @""),
			  @"FNPressed": NSLocalizedString(@"FN Key Pressed", @""),
			  @"FNReleased": NSLocalizedString(@"FN Key Released", @""),
			  @"ShiftPressed": NSLocalizedString(@"Shift Key Pressed", @""),
			  @"ShiftReleased": NSLocalizedString(@"Shift Key Released", @"")};
}
-(NSArray*)defaultNotifications {
	return @[@"CapsLockOn", @"CapsLockOff", @"FNPressed", @"FNReleased", @"ShiftPressed", @"ShiftReleased"];
}

@end
