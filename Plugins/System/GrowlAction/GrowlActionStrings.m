//
//  GrowlActionStrings.m
//  GrowlAction
//
//  Created by Daniel Siemer on 10/24/12.
//
//

#import "GrowlActionStrings.h"

@implementation GrowlActionStrings

-(instancetype)init {
	if((self = [super init])){
		self.titleLabel = NSLocalizedString(@"Title:", @"Automator action title label");
		self.descriptionLabel = NSLocalizedString(@"Description: (if blank, uses input)", @"Automator action description label");
		self.priorityLabel = NSLocalizedString(@"Priority:", @"Automator action priority label");
		self.stickyLabel = NSLocalizedString(@"Sticky", @"Automator action Sticky checkbox label");
		
		self.veryLowPriority = NSLocalizedString(@"Very Low", @"Very low priority");
		self.moderatePriority = NSLocalizedString(@"Moderate", @"Moderate priority");
		self.normalPriority = NSLocalizedString(@"Normal", @"Normal priority");
		self.highPriority = NSLocalizedString(@"High", @"High priority");
		self.emergencyPriority = NSLocalizedString(@"Emergency", @"Emergency priority");
	}
	return self;
}


@end
