//
//  GrowlNotificationCellView.h
//  Growl
//
//  Created by Daniel Siemer on 7/8/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface GrowlNotificationCellView : NSTableCellView{
    IBOutlet NSTextField *__weak description;
    IBOutlet NSImageView *__weak icon;
    IBOutlet NSButton *__weak deleteButton;
}
@property (weak) IBOutlet NSTextField *description;
@property (weak) IBOutlet NSImageView *icon;
@property (weak) IBOutlet NSButton *deleteButton;

@end
