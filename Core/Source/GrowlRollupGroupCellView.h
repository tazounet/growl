//
//  GrowlRollupGroupCellView.h
//  Growl
//
//  Created by Daniel Siemer on 8/13/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface GrowlRollupGroupCellView : NSTableCellView

@property (nonatomic, weak) IBOutlet NSButton *deleteButton;
@property (nonatomic, weak) IBOutlet NSButton *revealButton;
@property (nonatomic, weak) IBOutlet NSTextField *countLabel;
@property (nonatomic, weak) IBOutlet NSView *countBubble;

@end
