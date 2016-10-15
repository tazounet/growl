//
//  GrowlOnSwitch.m
//  GrowlSlider
//
//  Created by Daniel Siemer on 1/10/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "GrowlOnSwitch.h"

@implementation GrowlOnSwitch

@synthesize onLabel = _onLabel;
@synthesize offLabel = _offLabel;

- (instancetype)initWithFrame:(NSRect)frameRect
{
   if((self = [super initWithFrame:frameRect])){
      [self addObserver:self 
             forKeyPath:@"state" 
                options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                context:nil];
   }
   return self;
}

- (void)awakeFromNib {
   NSString *offString = NSLocalizedString(@"OFF", @"If the string is too long, use O");
   (self.offLabel).stringValue = offString;
   
   NSString *onString = NSLocalizedString(@"ON", @"If the string is too long, use I");
   (self.onLabel).stringValue = onString;
   [super awakeFromNib];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"state"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"state"])
    {
        self.onLabel.textColor = (self.state ? [NSColor blueColor] : [NSColor blackColor]);
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)setNilValueForKey:(NSString *)key
{
	if ([key isEqualToString:@"state"])
		[self setState:NO];
	else
		return [super setNilValueForKey:key];
}

- (BOOL)canBecomeKeyView
{
   return YES;
}

- (BOOL)acceptsFirstResponder
{
   return YES;
}

- (void)setHidden:(BOOL)flag {
	super.hidden = flag;
	(self.onLabel).hidden = flag;
	(self.offLabel).hidden = flag;
}

- (void)setEnabled:(BOOL)flag {
	super.enabled = flag;
	(self.onLabel).enabled = flag;
	(self.offLabel).enabled = flag;
}

@end
