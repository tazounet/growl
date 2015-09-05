//
//  HWGrowlAudioMonitor.m
//  HardwareGrowler
//
//  Created by Jerome Chauvin on 8/31/15.
//

#import "HWGrowlAudioMonitor.h"
#import <CoreAudio/CoreAudio.h>

@interface HWGrowlAudioMonitor ()

@property (nonatomic, unsafe_unretained) id<HWGrowlPluginControllerProtocol> delegate;

@end



@implementation HWGrowlAudioMonitor

@synthesize delegate;

-(void)audioOutputSourceChange:(AudioObjectPropertyAddress) inAddress {
    AudioDeviceID defaultDevice = 0;
    UInt32 defaultSize = sizeof(defaultDevice);

    const AudioObjectPropertyAddress defaultAddr = {
        kAudioHardwarePropertyDefaultOutputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };
    AudioObjectGetPropertyData(kAudioObjectSystemObject, &defaultAddr, 0, NULL, &defaultSize, &defaultDevice);
    
    UInt32 dataSourceId = 0;
    UInt32 dataSourceIdSize = sizeof(UInt32);
    AudioObjectGetPropertyData(defaultDevice, &inAddress, 0, NULL, &dataSourceIdSize, &dataSourceId);
 
    NSString *imageName = nil;
    NSString *outputName = nil;
    if (dataSourceId == 'ispk') {
        imageName = @"Audio-Speaker-On"; // TODO
        outputName = @"Internal Speaker";
        //NSLog(@"Output source changed: Internal Speaker");
    } else if (dataSourceId == 'hdpn') {
        imageName = @"Audio-Headphones-On"; // TODO
        outputName = @"Headphone";
        //NSLog(@"Output source changed: Headphone");
    }

    NSString *description = [NSString stringWithString:outputName];
    NSString *type = @"OutputSourceChanged";
    NSString *title = NSLocalizedString(@"Audio output source change", @"");
    
    // Get icon
    NSData *iconData = nil;
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:@"tif"];
    iconData = [NSData dataWithContentsOfFile:imagePath];
    
    [delegate notifyWithName:type
                       title:title
                 description:description
                        icon:iconData
            identifierString:outputName
               contextString:nil
                      plugin:self];
}

-(void)audioOutputChange:(AudioObjectPropertyAddress) inAddress {
    AudioDeviceID defaultDevice = 0;
    UInt32 defaultSize = sizeof(defaultDevice);
    CFStringRef deviceName = NULL;
    UInt32 dataSize = sizeof(deviceName);

    AudioObjectGetPropertyData(kAudioObjectSystemObject, &inAddress, 0, NULL, &defaultSize, &defaultDevice);
    
    const AudioObjectPropertyAddress sourceOutAddr = {
        kAudioDevicePropertyDeviceNameCFString,
        kAudioDevicePropertyScopeOutput,
        kAudioObjectPropertyElementMaster };
    
    AudioObjectGetPropertyData(defaultDevice, &sourceOutAddr, 0, NULL, &dataSize, &deviceName);
    //NSLog(@"Output changed: %@", (__bridge NSString *)deviceName);

    NSString *outputName = (__bridge NSString *)deviceName;
    NSString *description = [NSString stringWithString:outputName];
    NSString *type = @"OutputChanged";
    NSString *title = NSLocalizedString(@"Audio output change", @"");
    
    // Get icon
    NSData *iconData = nil;
    NSString *imageName = @"Audio-Speaker-On"; // TODO
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:@"tif"];
    iconData = [NSData dataWithContentsOfFile:imagePath];
    
    [delegate notifyWithName:type
                       title:title
                 description:description
                        icon:iconData
            identifierString:outputName
               contextString:nil
                      plugin:self];
}

-(void)audioInputChange:(AudioObjectPropertyAddress) inAddress {
    AudioDeviceID defaultDevice = 0;
    UInt32 defaultSize = sizeof(defaultDevice);
    CFStringRef deviceName = NULL;
    UInt32 dataSize = sizeof(deviceName);

    AudioObjectGetPropertyData(kAudioObjectSystemObject, &inAddress, 0, NULL, &defaultSize, &defaultDevice);
    
    const AudioObjectPropertyAddress sourceInAddr = {
        kAudioDevicePropertyDeviceNameCFString,
        kAudioDevicePropertyScopeInput,
        kAudioObjectPropertyElementMaster };
    
    AudioObjectGetPropertyData(defaultDevice, &sourceInAddr, 0, NULL, &dataSize, &deviceName);
    //NSLog(@"Input changed: %@", (__bridge NSString *)deviceName);
    
    NSString *inputName = (__bridge NSString *)deviceName;
    NSString *description = [NSString stringWithString:inputName];
    NSString *type = @"InputChanged";
    NSString *title = NSLocalizedString(@"Audio input change", @"");
    
    // Get icon
    NSData *iconData = nil;
    NSString *imageName = @"Audio-Microphone-On"; // TODO
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:@"tif"];
    iconData = [NSData dataWithContentsOfFile:imagePath];
    
    [delegate notifyWithName:type
                       title:title
                 description:description
                        icon:iconData
            identifierString:inputName
               contextString:nil
                      plugin:self];
}

-(void)postRegistrationInit {
    
    /*
     * input
     */
    const AudioObjectPropertyAddress inputAddress = {
        kAudioHardwarePropertyDefaultInputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster };

    [self audioInputChange:inputAddress];
    AudioObjectAddPropertyListenerBlock(kAudioObjectSystemObject, &inputAddress, dispatch_get_main_queue(), ^(UInt32 inNumberAddresses, const AudioObjectPropertyAddress *inAddresses) {
        for (UInt32 x=0; x<inNumberAddresses; x++) {
            [self audioInputChange:inAddresses[x]];
        }
    });

    /*
     * output
     */
    const AudioObjectPropertyAddress outputAddress = {
        kAudioHardwarePropertyDefaultOutputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster };

    [self audioOutputChange:outputAddress];
    AudioObjectAddPropertyListenerBlock(kAudioObjectSystemObject, &outputAddress, dispatch_get_main_queue(), ^(UInt32 inNumberAddresses, const AudioObjectPropertyAddress *inAddresses) {
        for (UInt32 x=0; x<inNumberAddresses; x++) {
            [self audioOutputChange:inAddresses[x]];
        }
    });
    
    /*
     * output data source
     */
    AudioDeviceID defaultDevice = 0;
    UInt32 defaultSize = sizeof(defaultDevice);

    const AudioObjectPropertyAddress defaultAddr = {
        kAudioHardwarePropertyDefaultOutputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };
    AudioObjectGetPropertyData(kAudioObjectSystemObject, &defaultAddr, 0, NULL, &defaultSize, &defaultDevice);

    const AudioObjectPropertyAddress outSourceAddr = {
        kAudioDevicePropertyDataSource,
        kAudioDevicePropertyScopeOutput,
        kAudioObjectPropertyElementMaster };

    [self audioOutputSourceChange:outSourceAddr];
    AudioObjectAddPropertyListenerBlock(defaultDevice, &outSourceAddr, dispatch_get_main_queue(), ^(UInt32 inNumberAddresses, const AudioObjectPropertyAddress *inAddresses) {
        for (UInt32 x=0; x<inNumberAddresses; x++) {
            [self audioOutputSourceChange:inAddresses[x]];
        }
    });

}


#pragma mark HWGrowlPluginProtocol

-(void)setDelegate:(id<HWGrowlPluginControllerProtocol>)aDelegate{
    delegate = aDelegate;
}

-(id<HWGrowlPluginControllerProtocol>)delegate {
    return delegate;
}

-(NSString*)pluginDisplayName {
    return NSLocalizedString(@"Audio Monitor", @"");
}

-(NSImage*)preferenceIcon {
    static NSImage *_icon = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _icon = [NSImage imageNamed:@"HWGPrefsDefault"];
    });
    return _icon;
}

-(NSView*)preferencePane {
    return nil;
}

#pragma mark HWGrowlPluginNotifierProtocol

-(NSArray*)noteNames {
    return [NSArray arrayWithObjects:@"InputChanged", @"OutputChanged", @"OutputSourceChanged", nil];
}

-(NSDictionary*)localizedNames {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            NSLocalizedString(@"Audio input change", @""), @"InputChanged",
            NSLocalizedString(@"Audio output change", @""), @"OutputChanged",
            NSLocalizedString(@"Audio output source change", @""), @"OutputSourceChanged",nil];
}

-(NSDictionary*)noteDescriptions {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            NSLocalizedString(@"Sent when the audio input change", @""), @"InputChanged",
            NSLocalizedString(@"Sent when the audio output change", @""), @"OutputChanged",
            NSLocalizedString(@"Sent when the audio output source change", @""), @"OutputSourceChanged",nil];
}

-(NSArray*)defaultNotifications {
    return [NSArray arrayWithObjects:@"InputChanged", @"OutputChanged", @"OutputSourceChanged", nil];
}

@end

