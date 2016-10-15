//
//  HWGrowlUSBMonitor.m
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/5/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "HWGrowlUSBMonitor.h"
#include <IOKit/IOKitLib.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/usb/IOUSBLib.h>
#include <IOKit/usb/USB.h>

static void usbDeviceAdded(void *refCon, io_iterator_t iterator);
static void usbDeviceRemoved(void *refCon, io_iterator_t iterator);

@interface HWGrowlUSBMonitor ()

@property (nonatomic, unsafe_unretained) id<HWGrowlPluginControllerProtocol> delegate;
@property (nonatomic, assign) BOOL notificationsArePrimed;

@property (nonatomic, assign) IONotificationPortRef ioKitNotificationPort;
@property (nonatomic, assign)	CFRunLoopSourceRef notificationRunLoopSource;

@end

@implementation HWGrowlUSBMonitor

@synthesize delegate;
@synthesize notificationsArePrimed;
@synthesize ioKitNotificationPort;
@synthesize notificationRunLoopSource;

-(void)dealloc {
	if (self.ioKitNotificationPort) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), self.notificationRunLoopSource, kCFRunLoopDefaultMode);
		IONotificationPortDestroy(self.ioKitNotificationPort);
	}
}

-(instancetype)init {
	if((self = [super init])){
		self.notificationsArePrimed = NO;

		self.ioKitNotificationPort = IONotificationPortCreate(kIOMasterPortDefault);
		self.notificationRunLoopSource = IONotificationPortGetRunLoopSource(ioKitNotificationPort);
		
		CFRunLoopAddSource(CFRunLoopGetCurrent(),
								 notificationRunLoopSource,
								 kCFRunLoopDefaultMode);
	}
	return self;
}

-(void)postRegistrationInit {
	[self registerForUSBNotifications];
}

-(void)registerForUSBNotifications {
	//http://developer.apple.com/documentation/DeviceDrivers/Conceptual/AccessingHardware/AH_Finding_Devices/chapter_4_section_2.html#//apple_ref/doc/uid/TP30000379/BABEACCJ
	kern_return_t	matchingResult;
	kern_return_t	removeNoteResult;
	io_iterator_t	addedIterator;
	io_iterator_t	removedIterator;
	
	//	NSLog(@"registerForUSBNotifications");
	
	//	Setup a matching Dictionary.
	CFDictionaryRef myMatchDictionary;
	myMatchDictionary = IOServiceMatching(kIOUSBDeviceClassName);
	
	//	Register our notification
	matchingResult = IOServiceAddMatchingNotification(ioKitNotificationPort,
																	  kIOFirstPublishNotification,
																	  myMatchDictionary,
																	  usbDeviceAdded,
																	  (__bridge void *)(self),
																	  &addedIterator);
	
	if (matchingResult)
		NSLog(@"matching notification registration failed: %d", matchingResult);
	
	//	Prime the Notifications (And Deal with the existing devices)...
	[self usbDeviceAdded:addedIterator];
	
	//	Register for removal notifications.
	//	It seems we have to make a new dictionary...  reusing the old one didn't work.
	
	myMatchDictionary = IOServiceMatching(kIOUSBDeviceClassName);
	removeNoteResult = IOServiceAddMatchingNotification(ioKitNotificationPort,
																		 kIOTerminatedNotification,
																		 myMatchDictionary,
																		 usbDeviceRemoved,
																		 (__bridge void *)(self),
																		 &removedIterator);
	
	// Matching notification must be "primed" by iterating over the
	// iterator returned from IOServiceAddMatchingNotification(), so
	// we call our device removed method here...
	//
	if (kIOReturnSuccess != removeNoteResult)
		NSLog(@"Couldn't add device removal notification");
	else
		[self usbDeviceRemoved:removedIterator];
		usbDeviceRemoved(NULL, removedIterator);
	
	self.notificationsArePrimed = YES;
}

-(void)usbDeviceID:(uint64_t)deviceID name:(NSString*)deviceName added:(BOOL)added {
	NSString *title = added ? NSLocalizedString(@"USB Connection", @"") : NSLocalizedString(@"USB Disconnection", @"");
	
    NSData *iconData = nil;
    NSString *imageName = added ? @"USB-On" : @"USB-Off";
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:@"tif"];
    iconData = [NSData dataWithContentsOfFile:imagePath];
	[delegate notifyWithName:added ? @"USBConnected" : @"USBDisconnected"
							 title:title
					 description:deviceName
							  icon:iconData
			  identifierString:[NSString stringWithFormat:@"%llu", deviceID]
				  contextString:nil
							plugin:self];
}

-(void)usbDeviceAdded:(io_iterator_t)iterator {
	//	NSLog(@"USB Device Added Notification.");
	io_object_t	thisObject;
	while ((thisObject = IOIteratorNext(iterator))) {
		if (self.notificationsArePrimed || delegate.onLaunchEnabled) {
			kern_return_t	nameResult;
			io_name_t		deviceNameChars;
			kern_return_t	idResult;
			uint64_t			deviceID;
			
			//	This works with USB devices...
			//	but apparently not firewire
			nameResult = IORegistryEntryGetName(thisObject, deviceNameChars);
			if (nameResult != KERN_SUCCESS) {
				NSLog(@"%s: Could not get name for USB object %u: IORegistryEntryGetName returned 0x%x", __PRETTY_FUNCTION__, thisObject, nameResult);
				continue;
			}
			
			idResult = IORegistryEntryGetRegistryEntryID(thisObject, &deviceID);
			if(idResult != KERN_SUCCESS) {
				NSLog(@"%s: Could not get EntryID for USB object %u: IORegistryEntryGetRegistryEntryID returned 0x%x", __PRETTY_FUNCTION__, thisObject, nameResult);
				continue;
			}
			
			NSString *deviceName = @(deviceNameChars);
			if (deviceName) {
				deviceName = [self deviceBusNameSwap:deviceName];
				
				// NSLog(@"USB Device Attached: %@" , deviceName);
				[self usbDeviceID:deviceID name:deviceName added:YES];
			}
		}
		
		IOObjectRelease(thisObject);
	}
}

static void usbDeviceAdded(void *refCon, io_iterator_t iterator) {
	HWGrowlUSBMonitor *monitor = (__bridge HWGrowlUSBMonitor*)refCon;
	[monitor usbDeviceAdded:iterator];
}

-(void)usbDeviceRemoved:(io_iterator_t)iterator {
	//	NSLog(@"USB Device Removed Notification.");
	io_object_t thisObject;
	while ((thisObject = IOIteratorNext(iterator))) {
		kern_return_t	nameResult;
		io_name_t		deviceNameChars;
		kern_return_t	idResult;
		uint64_t			deviceID;

		//	This works with USB devices...
		//	but apparently not firewire
		nameResult = IORegistryEntryGetName(thisObject, deviceNameChars);
		if (nameResult != KERN_SUCCESS) {
			NSLog(@"%s: Could not get name for USB object %u: IORegistryEntryGetName returned 0x%x", __PRETTY_FUNCTION__, thisObject, nameResult);
			continue;
		}
		
		idResult = IORegistryEntryGetRegistryEntryID(thisObject, &deviceID);
		if(idResult != KERN_SUCCESS) {
			NSLog(@"%s: Could not get EntryID for USB object %u: IORegistryEntryGetRegistryEntryID returned 0x%x", __PRETTY_FUNCTION__, thisObject, nameResult);
			continue;
		}
		
		NSString *deviceName = @(deviceNameChars);
		if (deviceName) {
			deviceName = [self deviceBusNameSwap:deviceName];
			
			// NSLog(@"USB Device Detached: %@" , deviceName);
			[self usbDeviceID:deviceID name:deviceName added:NO];
		}
		
		IOObjectRelease(thisObject);
	}
}

static void usbDeviceRemoved(void *refCon, io_iterator_t iterator) {
	HWGrowlUSBMonitor *monitor = (__bridge HWGrowlUSBMonitor*)refCon;
	[monitor usbDeviceRemoved:iterator];
}

-(NSString*)deviceBusNameSwap:(NSString*)deviceName {
	NSString *newName = deviceName;
	if (([deviceName compare:@"OHCI Root Hub Simulation"] == NSOrderedSame) ||
		 ([deviceName compare:@"UHCI Root Hub Simulation"] == NSOrderedSame)) {
		newName = NSLocalizedString(@"USB Bus", @"");
	} else if ([deviceName compare:@"EHCI Root Hub Simulation"] == NSOrderedSame ||
				  [deviceName compare:@"XHCI Root Hub USB 2.0 Simulation"] == NSOrderedSame) {
		newName = NSLocalizedString(@"USB 2.0 Bus", @"");
	} else if ([deviceName compare:@"XHCI Root Hub SS Simulation"] == NSOrderedSame) {
		newName = NSLocalizedString(@"USB 3.0 Bus", @"");
	}
	return newName;
}

#pragma mark HWGrowlPluginProtocol

-(void)setDelegate:(id<HWGrowlPluginControllerProtocol>)aDelegate{
	delegate = aDelegate;
}
-(id<HWGrowlPluginControllerProtocol>)delegate {
	return delegate;
}
-(NSString*)pluginDisplayName {
	return NSLocalizedString(@"USB Monitor", @"");
}
-(NSImage*)preferenceIcon {
	static NSImage *_icon = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_icon = [NSImage imageNamed:@"HWGPrefsUSB"];
	});
	return _icon;
}
-(NSView*)preferencePane {
	return nil;
}

#pragma mark HWGrowlPluginNotifierProtocol

-(NSArray*)noteNames {
	return @[@"USBConnected", @"USBDisconnected"];
}
-(NSDictionary*)localizedNames {
	return @{@"USBConnected": NSLocalizedString(@"USB Connected", @""),
			  @"USBDisconnected": NSLocalizedString(@"USB Disconnected", @"")};
}
-(NSDictionary*)noteDescriptions {
	return @{@"USBConnected": NSLocalizedString(@"Sent when a USB Device is connected", @""),
			  @"USBDisconnected": NSLocalizedString(@"Sent when a USB Device is disconnected", @"")};
}
-(NSArray*)defaultNotifications {
	return @[@"USBConnected", @"USBDisconnected"];
}

@end
