//
//  HWGrowlGraphicCardMonitor.m
//  HardwareGrowler
//
//  Created by Jerome Chauvin on 5/31/14.
//

#import "HWGrowlGraphicCardMonitor.h"
#include <IOKit/IOKitLib.h>
#include <IOKit/IOCFPlugIn.h>
#include "GSMux.h"

@interface HWGrowlGraphicCardMonitor ()

@property (nonatomic, assign) id<HWGrowlPluginControllerProtocol> delegate;

@end



@implementation HWGrowlGraphicCardMonitor

@synthesize delegate;

-(void)postRegistrationInit {
	[self registerForGraphicCardNotifications];
}

-(void)registerForGraphicCardNotifications {

    // Attempt to open a connection to AppleGraphicsControl.
    if (![GSMux switcherOpen]) {
        NSLog(@"Can't open connection to AppleGraphicsControl. This probably isn't a gfxCardStatus-compatible machine.");
        return;
    } else {
        NSLog(@"GPUs present: %@", [GSGPU getGPUNames]);
        NSLog(@"Integrated GPU name: %@", [GSGPU integratedGPUName]);
        NSLog(@"Discrete GPU name: %@", [GSGPU discreteGPUName]);
    }
    
    // Now accepting GPU change notifications! Apply at your nearest GSGPU today.
    [GSGPU registerForGPUChangeNotifications:self];
    
    BOOL integrated = [GSMux isUsingIntegratedGPU];
    [self GPUDidChangeTo:(integrated ? GSGPUTypeIntegrated : GSGPUTypeDiscrete)];
}

#pragma mark - GSGPUDelegate protocol

- (void)GPUDidChangeTo:(GSGPUType)gpu
{
    // TODO
    NSString *cardName = (gpu == GSGPUTypeIntegrated ? [GSGPU integratedGPUName] : [GSGPU discreteGPUName]);
    NSString *type = @"GraphicCardChange";
    NSData *iconData = nil;
    NSString *imageName = @"GraphicCard";
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:@"tif"];
    iconData = [NSData dataWithContentsOfFile:imagePath];
    
    [delegate notifyWithName:type
                       title:@"Graphic Card Change"
                 description:cardName
                        icon:iconData
            identifierString:cardName
               contextString:nil
                      plugin:self];

}

#pragma mark HWGrowlPluginProtocol

-(void)setDelegate:(id<HWGrowlPluginControllerProtocol>)aDelegate{
	delegate = aDelegate;
}

-(id<HWGrowlPluginControllerProtocol>)delegate {
	return delegate;
}

-(NSString*)pluginDisplayName {
	return NSLocalizedString(@"Graphic Card Monitor", @"");
}

-(NSImage*)preferenceIcon {
	static NSImage *_icon = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_icon = [[NSImage imageNamed:@"HWGPrefsDisplays"] retain];
	});
	return _icon;
}

-(NSView*)preferencePane {
	return nil;
}

#pragma mark HWGrowlPluginNotifierProtocol

-(NSArray*)noteNames {
	return [NSArray arrayWithObjects:@"GraphicCardChange", nil];
}

-(NSDictionary*)localizedNames {
	return [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"GraphicCard Change", @""), @"GraphicCardChange", nil];
}

-(NSDictionary*)noteDescriptions {
	return [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Sent when the Graphic Card change", @""), @"GraphicCardChange", nil];
}

-(NSArray*)defaultNotifications {
	return [NSArray arrayWithObjects:@"GraphicCardChange", nil];
}

@end

