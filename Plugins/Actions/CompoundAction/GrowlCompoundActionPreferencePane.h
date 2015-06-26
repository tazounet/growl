//
//  GrowlCompoundActionPreferencePane.h
//  Growl
//
//  Created by Daniel Siemer on 3/7/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlPluginPreferencePane.h"

@interface GrowlCompoundActionPreferencePane : GrowlPluginPreferencePane

@property (nonatomic, weak) IBOutlet NSArrayController *chosenArrayController;
@property (nonatomic, weak) IBOutlet NSArrayController *availableArrayController;
@property (nonatomic, weak) IBOutlet NSWindow *addWindow;

@end
