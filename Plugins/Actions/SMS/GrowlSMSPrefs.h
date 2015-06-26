//
//  GrowlSMSMePrefs.h
//  Display Plugins
//
//  Created by Diggory Laycock
//  Copyright 2005–2011 The Growl Project All rights reserved.
//

#import <GrowlPlugins/GrowlPluginPreferencePane.h>

@interface GrowlSMSPrefs: GrowlPluginPreferencePane {
}

@property (nonatomic, strong) NSString *smsNotifications;
@property (nonatomic, strong) NSString *accountRequiredLabel;
@property (nonatomic, strong) NSString *instructions;
@property (nonatomic, strong) NSString *accountLabel;
@property (nonatomic, strong) NSString *passwordLabel;
@property (nonatomic, strong) NSString *apiIDLabel;
@property (nonatomic, strong) NSString *destinationLabel;

- (NSString *) getAccountName;
- (void) setAccountName:(NSString *)value;

- (NSString *) getAccountAPIID;
- (void) setAccountAPIID:(NSString *)value;

- (NSString *) getDestinationNumber;
- (void) setDestinationNumber:(NSString *)value;

- (NSString *) accountPassword;
- (void) setAccountPassword:(NSString *)value;

@end
