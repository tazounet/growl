//
//  GrowlMailMePreferencePane.m
//  MailMe
//
//  Created by Daniel Siemer on 4/12/12.
//
//  This class represents your plugin's preference pane.  There will be only one instance, but possibly many configurations
//  In order to access a configuration values, use the NSMutableDictionary *configuration for getting them. 
//  In order to change configuration values, use [self setConfigurationValue:forKey:]
//  This ensures that the configuration gets saved into the database properly.

#import "GrowlMailMePreferencePane.h"
#import "SMTPClient.h"
#import <GrowlPlugins/GrowlKeychainUtilities.h>

@interface GrowlMailMePreferencePane ()

@property (nonatomic, strong) NSString *serverAddress;
@property (nonatomic, strong) NSString *serverPorts;
@property (nonatomic) NSInteger serverTlsMode;
@property (nonatomic) BOOL serverAuthFlag;
@property (nonatomic, strong) NSString *serverAuthUsername;
@property (nonatomic, strong) NSString *serverAuthPassword;
@property (nonatomic, strong) NSString *messageFrom;
@property (nonatomic, strong) NSString *messageTo;
@property (nonatomic, strong) NSString *messageSubject;

@property (nonatomic, strong) IBOutlet NSString *fromLabel;
@property (nonatomic, strong) IBOutlet NSString *toLabel;
@property (nonatomic, strong) IBOutlet NSString *prefixLabel;

@property (nonatomic, strong) IBOutlet NSString *smtpBoxLabel;

@property (nonatomic, strong) IBOutlet NSString *addressLabel;
@property (nonatomic, strong) IBOutlet NSString *portLabel;

@property (nonatomic, strong) IBOutlet NSString *securityLabel;
@property (nonatomic, strong) IBOutlet NSString *noneLabel;
@property (nonatomic, strong) IBOutlet NSString *tlsLabel;
@property (nonatomic, strong) IBOutlet NSString *tlsOrCloseLabel;

@property (nonatomic, strong) IBOutlet NSString *authenticationCheckboxLabel;
@property (nonatomic, strong) IBOutlet NSString *usernameLabel;
@property (nonatomic, strong) IBOutlet NSString *passwordLabel;

@end

@implementation GrowlMailMePreferencePane

@dynamic serverAddress;
@dynamic serverPorts;
@dynamic serverTlsMode;
@dynamic serverAuthFlag;
@dynamic serverAuthUsername;
@dynamic serverAuthPassword;
@dynamic messageFrom;
@dynamic messageTo;
@dynamic messageSubject;

@synthesize fromLabel;
@synthesize toLabel;
@synthesize prefixLabel;
@synthesize smtpBoxLabel;
@synthesize addressLabel;
@synthesize portLabel;
@synthesize securityLabel;
@synthesize noneLabel;
@synthesize tlsLabel;
@synthesize tlsOrCloseLabel;
@synthesize authenticationCheckboxLabel;
@synthesize usernameLabel;
@synthesize passwordLabel;

-(instancetype)initWithBundle:(NSBundle *)bundle {
	if((self = [super initWithBundle:bundle])){
		self.fromLabel = NSLocalizedStringFromTableInBundle(@"From:", @"Localizable", bundle, @"Title for from field");
		self.toLabel = NSLocalizedStringFromTableInBundle(@"To:", @"Localizable", bundle, @"Title for to field");
		self.prefixLabel = NSLocalizedStringFromTableInBundle(@"Subject prefix:", @"Localizable", bundle, @"Title for subject prefix field");
		self.smtpBoxLabel = NSLocalizedStringFromTableInBundle(@"SMTP Server:", @"Localizable", bundle, @"Title for box containing SMTP server details");
		self.addressLabel = NSLocalizedStringFromTableInBundle(@"Address:", @"Localizable", bundle, @"SMTP Server address");
		self.portLabel = NSLocalizedStringFromTableInBundle(@"Port:", @"Localizable", bundle, @"SMTP Server port");
		self.securityLabel = NSLocalizedStringFromTableInBundle(@"Security:", @"Localizable", bundle, @"Security options title");
		self.noneLabel = NSLocalizedStringFromTableInBundle(@"None", @"Localizable", bundle, @"No security option");
		self.tlsLabel = NSLocalizedStringFromTableInBundle(@"TLS if possible", @"Localizable", bundle, @"TLS if possible security option");
		self.tlsOrCloseLabel = NSLocalizedStringFromTableInBundle(@"TLS or close", @"Localizable", bundle, @"TLS or close security option");
		self.authenticationCheckboxLabel = NSLocalizedStringFromTableInBundle(@"Authentication", @"Localizable", bundle, @"Authentication checkbox");
		self.usernameLabel = NSLocalizedStringFromTableInBundle(@"Username:", @"Localizable", bundle, @"Username field");
		self.passwordLabel = NSLocalizedStringFromTableInBundle(@"Password:", @"Localizable", bundle, @"password field");
	}
	return self;
}


-(NSString*)mainNibName {
	return @"MailMePrefPane";
}

/* This returns the set of keys the preference pane needs updated via bindings 
 * This is called by GrowlPluginPreferencePane when it has had its configuration swapped
 * Since we really only need a fixed set of keys updated, use dispatch_once to create the set
 */
- (NSSet*)bindingKeys {
	static NSSet *keys = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keys = [NSSet setWithObjects:@"serverAddress",
					@"serverPorts",
					@"serverTlsMode",
					@"serverAuthFlag",
					@"serverAuthUsername",
					@"serverAuthPassword",
					@"messageFrom",
					@"messageTo",
					@"messageSubject", nil];
	});
	return keys;
}

/* This method is called when our configuration values have been changed 
 * by switching to a new configuration.  This is where we would update certain things
 * that are unbindable.  Call the super version in order to ensure bindingKeys is also called and used.
 * Uncomment the method to use.
 */
/*
-(void)updateConfigurationValues {
	[super updateConfigurationValues];
}
*/

-(NSString*)serverAddress {
	return [self.configuration valueForKey:SMTPServerAddressKey];
}
-(void)setServerAddress:(NSString*)value {
	if(value.length == 0)
		value = nil;
	[self setConfigurationValue:value forKey:SMTPServerAddressKey];
}

-(NSString*)serverPorts {
	return [self.configuration valueForKey:SMTPServerPortsKey];
}
-(void)setServerPorts:(NSString*)value {
	if(value.length == 0)
		value = nil;
	[self setConfigurationValue:value forKey:SMTPServerPortsKey];
}

-(NSInteger)serverTlsMode {
	NSInteger value = SMTPClientTLSModeTLSIfPossible;
	if([self.configuration valueForKey:SMTPServerTLSModeKey])
		value = [[self.configuration valueForKey:SMTPServerTLSModeKey] integerValue];
	return value;
}
-(void)setServerTlsMode:(NSInteger)value {
	[self setConfigurationValue:@(value) forKey:SMTPServerTLSModeKey];
}

-(BOOL)serverAuthFlag {
	BOOL value = NO;
	if([self.configuration valueForKey:SMTPServerAuthFlagKey])
		value = [[self.configuration valueForKey:SMTPServerAuthFlagKey] boolValue];
	return value;
}
-(void)setServerAuthFlag:(BOOL)value {
	[self setConfigurationValue:@(value) forKey:SMTPServerAuthFlagKey];
}

-(NSString*)serverAuthUsername {
	return [self.configuration valueForKey:SMTPServerAuthUsernameKey];
}
-(void)setServerAuthUsername:(NSString*)value {
	if(value.length == 0)
		value = nil;
	[self setConfigurationValue:value forKey:SMTPServerAuthUsernameKey];
}

-(NSString*)serverAuthPassword {
	return [GrowlKeychainUtilities passwordForServiceName:@"Growl-MailMe" accountName:self.configurationID];
}
-(void)setServerAuthPassword:(NSString*)value {
	[GrowlKeychainUtilities setPassword:value forService:@"Growl-MailMe" accountName:self.configurationID];
}

-(NSString*)messageFrom {
	return [self.configuration valueForKey:SMTPFromKey];
}
-(void)setMessageFrom:(NSString*)value {
	if(value.length == 0)
		value = nil;
	[self setConfigurationValue:value forKey:SMTPFromKey];
}

-(NSString*)messageTo {
	return [self.configuration valueForKey:SMTPToKey];
}
-(void)setMessageTo:(NSString*)value {
	if(value.length == 0)
		value = nil;
	[self setConfigurationValue:value forKey:SMTPToKey];
}

-(NSString*)messageSubject {
	return [self.configuration valueForKey:SMTPSubjectKey];
}
-(void)setMessageSubject:(NSString*)value {
	if(value.length == 0)
		value = nil;
	[self setConfigurationValue:value forKey:SMTPSubjectKey];
}

@end
