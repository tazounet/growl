//
//  GrowlActionStrings.h
//  GrowlAction
//
//  Created by Daniel Siemer on 10/24/12.
//
//

#import <Foundation/Foundation.h>

@interface GrowlActionStrings : NSObject

@property (nonatomic, strong) NSString *titleLabel;
@property (nonatomic, strong) NSString *descriptionLabel;
@property (nonatomic, strong) NSString *priorityLabel;
@property (nonatomic, strong) NSString *stickyLabel;

@property (nonatomic, strong) NSString *veryLowPriority;
@property (nonatomic, strong) NSString *moderatePriority;
@property (nonatomic, strong) NSString *normalPriority;
@property (nonatomic, strong) NSString *highPriority;
@property (nonatomic, strong) NSString *emergencyPriority;

@end
