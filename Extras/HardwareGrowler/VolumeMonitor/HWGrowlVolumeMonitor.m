//
//  HWGrowlVolumeMonitor.m
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/3/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "HWGrowlVolumeMonitor.h"

#define VolumeNotifierUnmountWaitSeconds	600.0
#define VolumeEjectCacheInfoIndex			0
#define VolumeEjectCacheTimerIndex			1

@implementation VolumeInfo

@synthesize iconData;
@synthesize path;
@synthesize name;

+ (NSImage*)ejectIconImage {
	static NSImage *_ejectIconImage = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_ejectIconImage = [NSImage imageNamed:@"DisksVolumes-Eject"];
	});
	return _ejectIconImage;
}

+ (NSData*)mountIconData {
	static NSData *_mountIconData = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
        NSArray *representations = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericRemovableMediaIcon)].representations;
        NSBitmapImageRep *bitmapRep = representations[0U];

		_mountIconData = [bitmapRep representationUsingType: NSPNGFileType
                                                 properties: @{NSImageCompressionFactor: @2.0f}];
	});
	return _mountIconData;
}

+ (VolumeInfo *) volumeInfoForMountWithPath:(NSString *)aPath {
	return [[VolumeInfo alloc] initForMountWithPath:aPath];
}

+ (VolumeInfo *) volumeInfoForUnmountWithPath:(NSString *)aPath {
	return [[VolumeInfo alloc] initForUnmountWithPath:aPath];
}

- (instancetype) initForMountWithPath:(NSString *)aPath {
	if ((self = [self initWithPath:aPath])) {
		if (path) {
            NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
            CGImageRef iconRef = [icon CGImageForProposedRect:nil context:nil hints:nil];
            NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:iconRef];
			self.iconData = [bitmapRep representationUsingType: NSPNGFileType
                                                    properties: @{NSImageCompressionFactor: @2.0f}];
		} else {
			self.iconData = [VolumeInfo mountIconData];
		}
	}
	
	return self;
}

- (instancetype) initForUnmountWithPath:(NSString *)aPath {
	if ((self = [self initWithPath:aPath])) {
		if (path) {
			//Get the icon for the volume.
			NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
			NSSize iconSize = icon.size;
			//Also get the standard Eject icon.
			NSImage *ejectIcon = [VolumeInfo ejectIconImage];
			NSSize ejectIconSize = ejectIcon.size;
			
			//Badge the volume icon with the Eject icon. This is what we'll pass off te Growl.
			//The badge's width and height are 2/3 of the overall icon's width and height. If they were 1/2, it would look small (so I found in testing —boredzo). This looks pretty good.
			[icon lockFocus];
			
			[ejectIcon drawInRect:CGRectMake(0.0f, 0.0f, iconSize.width, iconSize.width)
							 fromRect:(NSRect){ NSZeroPoint, ejectIconSize }
							operation:NSCompositingOperationSourceOver
							 fraction:1.0f];
			
			//For some reason, passing [icon TIFFRepresentation] only passes the unbadged volume icon to Growl, even though writing the same TIFF data out to a file and opening it in Preview does show the badge. If anybody can figure that out, you're welcome to do so. Until then:
			//We get a NSBIR for the current focused view (the image), and make PNG data from it. (There is no reason why this could not be TIFF if we wanted it to be. I just generally prefer PNG. —boredzo)
			NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){ NSZeroPoint, iconSize }];
            self.iconData = [imageRep representationUsingType:NSPNGFileType properties:@{NSImageCompressionFactor: @2.0f}];
			
			[icon unlockFocus];
		} else {
            self.iconData = [VolumeInfo ejectIconImage].TIFFRepresentation;
        }
	}
	
	return self;
}

- (instancetype) initWithPath:(NSString *)aPath {
	if ((self = [super init])) {
		if (aPath) {
			path = aPath;
			name = [[NSFileManager defaultManager] displayNameAtPath:path];
		}
	}
	
	return self;
}


- (NSString *) description {
	NSMutableDictionary *desc = [NSMutableDictionary dictionary];
	
	if (name)
		desc[@"name"] = name;
	if (path)
		desc[@"path"] = path;
	if (iconData)
		desc[@"iconData"] = @"<yes>";
	
	return desc.description;
}

@end

@interface HWGrowlVolumeMonitor ()

@property (nonatomic, unsafe_unretained) id<HWGrowlPluginControllerProtocol> delegate;
@property (nonatomic, strong) NSMutableDictionary *ejectCache;
@property (nonatomic, strong) NSString *ignoredVolumeColumnTitle;

@property (nonatomic, weak) IBOutlet NSArrayController *arrayController;
@property (nonatomic, weak) IBOutlet NSTableView *tableView;

@end

@implementation HWGrowlVolumeMonitor

@synthesize delegate;
@synthesize ejectCache;

@synthesize prefsView;
@synthesize arrayController;
@synthesize tableView;

-(instancetype)init {
	if((self = [super init])){
		self.ejectCache = [NSMutableDictionary dictionary];
		
		NSNotificationCenter *center = [NSWorkspace sharedWorkspace].notificationCenter;
		
		[center addObserver:self selector:@selector(volumeDidMount:) name:NSWorkspaceDidMountNotification object:nil];
		//Note that we must use both WILL and DID unmount, so we can only get the volume's icon before the volume has finished unmounting.
		//The icon and data is stored during WILL unmount, and then displayed during DID unmount.
		[center addObserver:self selector:@selector(volumeDidUnmount:) name:NSWorkspaceDidUnmountNotification object:nil];
		[center addObserver:self selector:@selector(volumeWillUnmount:) name:NSWorkspaceWillUnmountNotification object:nil];
		
		self.ignoredVolumeColumnTitle = NSLocalizedString(@"Ignored Drives:", @"Title for colum in table of ignored volumes");
	}
	return self;
}

- (void)dealloc {
	[[NSWorkspace sharedWorkspace].notificationCenter removeObserver:self];
	
	[ejectCache enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[obj[VolumeEjectCacheTimerIndex] invalidate];
	}];		
	
	

}

- (void) sendMountNotificationForVolume:(VolumeInfo*)volume mounted:(BOOL)mounted {
	NSArray *exceptions = [[NSUserDefaults standardUserDefaults] objectForKey:@"HWGVolumeMonitorExceptions"];
	__block BOOL found = NO;
	[exceptions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSString *justAString = [obj valueForKey:@"justastring"];
		NSString *path = volume.path;
		NSString *name = volume.name;
		BOOL hasWildCard = [justAString hasSuffix:@"*"];
		if(!hasWildCard){
			if([path caseInsensitiveCompare:justAString] == NSOrderedSame ||
				[name caseInsensitiveCompare:justAString] == NSOrderedSame)
			{
				found = YES;
				*stop = YES;
			}
		}else{
			justAString = [justAString substringToIndex:justAString.length - 1];
			if([path rangeOfString:justAString options:(NSAnchoredSearch | NSCaseInsensitivePredicateOption)].location != NSNotFound ||
				[name rangeOfString:justAString options:(NSAnchoredSearch | NSCaseInsensitivePredicateOption)].location != NSNotFound)
			{
				found = YES;
				*stop = YES;
			}
		}
	}];
	if(found)
		return;
	
	NSString *context = mounted ? volume.path : nil;
	NSString *type = mounted ? @"VolumeMounted" : @"VolumeUnmounted";
	NSString *title = [NSString stringWithFormat:@"%@ %@", volume.name, mounted ? NSLocalizedString(@"Mounted", @"") : NSLocalizedString(@"Unmounted", @"")];
	[delegate notifyWithName:type
							 title:title
					 description:mounted ? NSLocalizedString(@"Click to open", @"Message body on a volume mount notification, clicking it opens the drive in finder") : nil
							  icon:volume.iconData
			  identifierString:volume.path
				  contextString:context 
							plugin:self];
}

- (void) staleEjectItemTimerFired:(NSTimer *)theTimer {
	VolumeInfo *info = theTimer.userInfo;
	
	[ejectCache removeObjectForKey:info.path];
}

- (void) volumeDidMount:(NSNotification *)aNotification {
	//send notification
	VolumeInfo *volume = [VolumeInfo volumeInfoForMountWithPath:aNotification.userInfo[@"NSDevicePath"]];
	[self sendMountNotificationForVolume:volume mounted:YES];
}

- (void) volumeWillUnmount:(NSNotification *)aNotification {
	NSString *path = aNotification.userInfo[@"NSDevicePath"];
	
	if (path) {
		VolumeInfo *info = [VolumeInfo volumeInfoForUnmountWithPath:path];
		NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:VolumeNotifierUnmountWaitSeconds
																		  target:self
																		selector:@selector(staleEjectItemTimerFired:)
																		userInfo:info
																		 repeats:NO];
		
		// need to invalidate the timer for a previous item if it exists
		NSArray *cacheItem = ejectCache[path];
		if (cacheItem)
			[cacheItem[VolumeEjectCacheTimerIndex] invalidate];
		
		ejectCache[path] = @[info, timer];
	}
}

- (void) volumeDidUnmount:(NSNotification *)aNotification {
	VolumeInfo *info = nil;
	NSString *path = aNotification.userInfo[@"NSDevicePath"];
	NSArray *cacheItem = path ? ejectCache[path] : nil;
	
	if (cacheItem)
		info = cacheItem[VolumeEjectCacheInfoIndex];
	else
		info = [VolumeInfo volumeInfoForUnmountWithPath:path];
	
	//Send notification
	[self sendMountNotificationForVolume:info mounted:NO];
	
	if (cacheItem) {
		[cacheItem[VolumeEjectCacheTimerIndex] invalidate];
		// we need to remove the item from the cache AFTER calling volumeDidUnmount so that "info" stays
		// retained long enough to be useful. After this next call, "info" is no longer valid.
		[ejectCache removeObjectForKey:path];
		info = nil;
	}
}

#pragma mark UI

-(void)tableViewSelectionDidChange:(NSNotification *)notification {
   NSArray *arranged = arrayController.arrangedObjects;
   NSUInteger selection = arrayController.selectionIndex;
   if(selection < arranged.count && arranged.count){
      NSString *justastring = [arranged[selection] valueForKey:@"justastring"];
      if(!justastring || [justastring isEqualToString:@""])
         [self.tableView editColumn:0 row:selection withEvent:nil select:YES];
   }
}

-(IBAction)addVolumeEntry:(id)sender {
   NSMutableDictionary *dict = [NSMutableDictionary dictionary];
   [self.arrayController addObject:dict];
   [self.arrayController setSelectedObjects:@[dict]];
}
#pragma mark HWGrowlPluginProtocol

-(void)setDelegate:(id<HWGrowlPluginControllerProtocol>)aDelegate{
	delegate = aDelegate;
}
-(id<HWGrowlPluginControllerProtocol>)delegate {
	return delegate;
}
-(NSString*)pluginDisplayName{
	return NSLocalizedString(@"Volume Monitor", @"");
}
-(NSImage*)preferenceIcon {
	static NSImage *_icon = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_icon = [NSImage imageNamed:@"HWGPrefsDrivesVolumes"];
	});
	return _icon;
}
-(NSView*)preferencePane {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        [bundle loadNibNamed:@"VolumeMonitorPrefs" owner:self topLevelObjects:nil];
	});
	return prefsView;
}

#pragma mark HWGrowlPluginNotifierProtocol

-(NSArray*)noteNames {
	return @[@"VolumeMounted", @"VolumeUnmounted"];
}
-(NSDictionary*)localizedNames {
	return @{@"VolumeMounted": NSLocalizedString(@"Volume Mounted", @""),
			  @"VolumeUnmounted": NSLocalizedString(@"Volume Unmounted", @"")};
}
-(NSDictionary*)noteDescriptions {
	return @{@"VolumeMounted": NSLocalizedString(@"Sent when a volume is mounted", @""),
			  @"VolumeUnmounted": NSLocalizedString(@"Sent when a volume is unmounted", @"")};
}
-(NSArray*)defaultNotifications {
	return @[@"VolumeMounted", @"VolumeUnmounted"];
}

-(void)fireOnLaunchNotes{
    NSArray *paths = [[NSFileManager defaultManager] mountedVolumeURLsIncludingResourceValuesForKeys:nil options:0];
	__weak HWGrowlVolumeMonitor *weakSelf = self;
	[paths enumerateObjectsUsingBlock:^(NSURL* obj, NSUInteger idx, BOOL *stop) {
		[weakSelf sendMountNotificationForVolume:[VolumeInfo volumeInfoForMountWithPath:obj.path] mounted:YES];
	}];
}
-(void)noteClosed:(NSString*)contextString byClick:(BOOL)clicked {
	if(clicked)
		[[NSWorkspace sharedWorkspace] openFile:contextString];
}

@end
