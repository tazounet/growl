//
//  GSMux.m
//  gfxCardStatus
//
//  Created by Cody Krieger on 6/21/11.
//  Copyright 2011 Cody Krieger. All rights reserved.
//
//  The following code has been adapted from ah's original version 
//  (from the MacRumors forums). See switcher.h/m early on in repo history 
//  for original logic.
//
//  Updated for HardwareGrowler usage by Jerome Chauvin
//

#import "GSMux.h"
#import "GSGPU.h"

#define kNewStyleSwitchPolicyValue (0) // dynamic switching
#define kOldStyleSwitchPolicyValue (2) // log out before switching

static io_connect_t _switcherConnect = IO_OBJECT_NULL;

// Stuff to look at:
// nvram -p -> gpu_policy
// bootargs: agc=0/1: flags in dmesg
// Compile: gcc -o switcher switcher.c -framework IOKit
// Enable logging to kernel.log:
// Add agclog=10000 agcdebug=4294967295 to com.apple.Boot.plist

// User client method dispatch selectors.
enum {
    kOpen,
    kClose,
    kSetMuxState,
    kGetMuxState,
    kSetExclusive,
    kDumpState,
    kUploadEDID,
    kGetAGCData,
    kGetAGCData_log1,
    kGetAGCData_log2,
    kNumberOfMethods
};

typedef NS_ENUM (NSInteger, muxState) {
    muxDisableFeature    = 0, // set only
    muxEnableFeature    = 1, // set only
    
    muxFeatureInfo        = 0, // get: returns a uint64_t with bits set according to FeatureInfos, 1=enabled
    muxFeatureInfo2        = 1, // get: same as MuxFeatureInfo
    
    muxForceSwitch        = 2, // set: force Graphics Switch regardless of switching mode
    // get: always returns 0xdeadbeef
    
    muxPowerGPU            = 3, // set: power down a gpu, pretty useless since you can't power down the igp and the dedicated gpu is powered down automatically
    // get: maybe returns powered on graphics cards, 0x8 = integrated, 0x88 = discrete (or probably both, since integrated never gets powered down?)
    
    muxGpuSelect        = 4, // set/get: Dynamic Switching on/off with [2] = 0/1 (the same as if you click the checkbox in systemsettings.app)
    
    // TODO: Test what happens on older mbps when switchpolicy = 0
    // Changes if you're able to switch in systemsettings.app without logout
    muxSwitchPolicy        = 5, // set: 0 = dynamic switching, 2 = no dynamic switching, exactly like older mbp switching, 3 = no dynamic stuck, others unsupported
    // get: possibly inverted?
    
    muxUnknown            = 6, // get: always 0xdeadbeef
    
    muxGraphicsCard        = 7, // get: returns active graphics card
    muxUnknown2            = 8, // get: sometimes 0xffffffff, TODO: figure out what that means
    
};

typedef NS_ENUM (NSInteger, muxFeature) {
    Policy,
    Auto_PowerDown_GPU,
    Dynamic_Switching,
    GPU_Powerpolling, // Inverted: Disable Feature enables it and vice versa
    Defer_Policy,
    Synchronous_Launch,
    Backlight_Control=8,
    Recovery_Timeouts,
    Power_Switch_Debounce,
    Logging=16,
    Display_Capture_Switch,
    No_GL_HDA_busy_idle_registration,
    muxFeaturesCount
};

#pragma mark - Static C methods

static BOOL getMuxState(io_connect_t connect, uint64_t input, uint64_t *output)
{
    kern_return_t kernResult;
    uint32_t outputCount = 1;
    uint64_t scalarI_64[2] = { 1 /* Always 1 (kMuxControl?) */, input /* Feature Info */ };
    
    kernResult = IOConnectCallScalarMethod(connect,       // an io_connect_t returned from IOServiceOpen().
                                           kGetMuxState,  // selector of the function to be called via the user client.
                                           scalarI_64,    // array of scalar (64-bit) input values.
                                           2,             // the number of scalar input values.
                                           output,        // array of scalar (64-bit) output values.
                                           &outputCount); // pointer to the number of scalar output values.
    
    if (kernResult == KERN_SUCCESS)
        NSLog(@"getMuxState was successful (count=%d, value=0x%08llx).", outputCount, *output);
    else
        NSLog(@"getMuxState returned 0x%08x.", kernResult);
    
    return kernResult == KERN_SUCCESS;
}


// --------------------------------------------------------------

typedef struct StateStruct {
uint32_t field1[25]; // State Struct has to be 100 bytes long
} StateStruct;


@implementation GSMux

#pragma mark - GSMux API
#pragma mark Initialization/destruction

+ (BOOL)switcherOpen
{
    kern_return_t kernResult = 0; 
    io_service_t service = IO_OBJECT_NULL;
    io_iterator_t iterator = IO_OBJECT_NULL;
    
    // Look up the objects we wish to open.
    // This creates an io_iterator_t of all instances of our driver that exist in the I/O Registry.
    kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(kDriverClassName), &iterator);    
    if (kernResult != KERN_SUCCESS) {
        NSLog(@"IOServiceGetMatchingServices returned 0x%08x.", kernResult);
        return NO;
    }
    
    service = IOIteratorNext(iterator); // actually there is only 1 such service
    IOObjectRelease(iterator);
    if (service == IO_OBJECT_NULL) {
        NSLog(@"No matching drivers found.");
        return NO;
    }
    
    // This call will cause the user client to be instantiated. It returns an io_connect_t handle
    // that is used for all subsequent calls to the user client.
    // Applications pass the bad-Bit (indicates they need the dedicated gpu here)
    // as uint32_t type, 0 = no dedicated gpu, 1 = dedicated
    kernResult = IOServiceOpen(service, mach_task_self(), 0, &_switcherConnect);
    if (kernResult != KERN_SUCCESS) {
        NSLog(@"IOServiceOpen returned 0x%08x.", kernResult);
        return NO;
    }
    
    kernResult = IOConnectCallScalarMethod(_switcherConnect, kOpen, NULL, 0, NULL, NULL);
    if (kernResult != KERN_SUCCESS)
        NSLog(@"IOConnectCallScalarMethod returned 0x%08x.", kernResult);
    else
        NSLog(@"Driver connection opened.");
    
    return kernResult == KERN_SUCCESS;
}

+ (void)switcherClose
{
    kern_return_t kernResult;
    if (_switcherConnect == IO_OBJECT_NULL) return;
    
    kernResult = IOConnectCallScalarMethod(_switcherConnect, kClose, NULL, 0, NULL, NULL);
    if (kernResult != KERN_SUCCESS) NSLog(@"IOConnectCallScalarMethod returned 0x%08x.", kernResult);
    
    kernResult = IOServiceClose(_switcherConnect);
    if (kernResult != KERN_SUCCESS) NSLog(@"IOServiceClose returned 0x%08x.", kernResult);
    
    _switcherConnect = IO_OBJECT_NULL;
    NSLog(@"Driver connection closed.");
}

+ (BOOL)isUsingIntegratedGPU
{
    uint64_t output;
    if (_switcherConnect == IO_OBJECT_NULL) return NO;
    getMuxState(_switcherConnect, muxGraphicsCard, &output);
    return output != 0;
}

+ (BOOL)isUsingDiscreteGPU
{
    return ![self isUsingIntegratedGPU];
}

+ (BOOL)isUsingDynamicSwitching
{
    uint64_t output;
    if (_switcherConnect == IO_OBJECT_NULL) return NO;
    getMuxState(_switcherConnect, muxGpuSelect, &output);
    return output != 0;
}

+ (BOOL)isUsingOldStyleSwitchPolicy
{
    uint64_t policy = 0;
    getMuxState(_switcherConnect, muxSwitchPolicy, &policy);
    return policy == kOldStyleSwitchPolicyValue;
}

+ (BOOL)isOnIntegratedOnlyMode
{
    return [self isUsingIntegratedGPU] && ([self isUsingOldStyleSwitchPolicy] || [GSGPU is2010MacBookPro]);
}

+ (BOOL)isOnDiscreteOnlyMode
{
    return [self isUsingDiscreteGPU] && ([self isUsingOldStyleSwitchPolicy] || [GSGPU is2010MacBookPro]);
}

@end
