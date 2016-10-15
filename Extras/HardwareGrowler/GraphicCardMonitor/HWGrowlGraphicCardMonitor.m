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
#include "GSProcess.h"

@interface HWGrowlGraphicCardMonitor ()

@property (nonatomic, unsafe_unretained) id<HWGrowlPluginControllerProtocol> delegate;

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
    NSString *cardName = (gpu == GSGPUTypeIntegrated ? [GSGPU integratedGPUName] : [GSGPU discreteGPUName]);
    NSString *description = [NSString stringWithString:cardName];
    NSString *type = (gpu == GSGPUTypeIntegrated ? @"OnIntegratedGraphicCard" : @"OnDiscreteGraphicCard");
    NSString *title = (gpu == GSGPUTypeIntegrated ? NSLocalizedString(@"On integrated graphic card", @"") : NSLocalizedString(@"On discrete graphic card", @""));

    // Get icon
    NSData *iconData = nil;
    NSString *imageName = (gpu == GSGPUTypeIntegrated ? @"GraphicCard" : @"GraphicCard"); // TODO
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:@"tif"];
    iconData = [NSData dataWithContentsOfFile:imagePath];

    // If we're using a 9400M/9600M GT model, or if we're on the integrated GPU,
    // no need to display/update the dependencies list.
    BOOL notUpdateProcessList = (gpu == GSGPUTypeIntegrated) || [GSGPU isLegacyMachine];

    if (! notUpdateProcessList)
    {
        NSLog(@"Updating process list...");

        NSArray *processes = [GSProcess getTaskList];

        for (NSDictionary *dict in processes)
        {
            NSString *taskName = dict[kTaskItemName];
            NSString *pid = dict[kTaskItemPID];
            NSString *taskTitle = [NSString stringWithString:taskName];
            
            if (![pid isEqualToString:@""])
            {
                taskTitle = [taskTitle stringByAppendingFormat:@", PID: %@", pid];
            }
        
            // Update description
            description = [description stringByAppendingFormat:@"\n%@", taskTitle];
        }
    }

    [delegate notifyWithName:type
                       title:title
                 description:description
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
		_icon = [NSImage imageNamed:@"HWGPrefsDefault"];
	});
	return _icon;
}

-(NSView*)preferencePane {
	return nil;
}

#pragma mark HWGrowlPluginNotifierProtocol

-(NSArray*)noteNames {
	return @[@"OnIntegratedGraphicCard", @"OnDiscreteGraphicCard"];
}

-(NSDictionary*)localizedNames {
	return @{@"OnIntegratedGraphicCard": NSLocalizedString(@"On integrated graphic card", @""),
            @"OnDiscreteGraphicCard": NSLocalizedString(@"On discrete graphic card", @"")};
}

-(NSDictionary*)noteDescriptions {
	return @{@"OnIntegratedGraphicCard": NSLocalizedString(@"Sent when the graphic card change to integrated", @""),
            @"OnDiscreteGraphicCard": NSLocalizedString(@"Sent when the graphic card change to discrete", @"")};
}

-(NSArray*)defaultNotifications {
	return @[@"OnIntegratedGraphicCard", @"OnDiscreteGraphicCard"];
}

@end

