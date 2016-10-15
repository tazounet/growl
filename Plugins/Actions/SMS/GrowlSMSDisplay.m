//
//  GrowlSMSDisplay.m
//  Growl Display Plugins
//
//  Created by Diggory Laycock
//  Copyright 2005–2011 The Growl Project All rights reserved.
//
#import <GrowlPlugins/GrowlNotification.h>
#import "GrowlSMSDisplay.h"
#import "GrowlSMSPrefs.h"
#import "NSStringAdditions.h"
#import "GrowlDefinesInternal.h"
#import <GrowlPlugins/GrowlKeychainUtilities.h>

@implementation GrowlSMSDisplay

- (instancetype) init {
	if ((self = [super init])) {
		commandQueue = [[NSMutableArray alloc] init];
		xmlHoldingStringValue = [[NSMutableString alloc] init];
		waitingForResponse = NO;
		creditBalance = 0.0;
		self.prefDomain = GrowlSMSPrefDomain;
	}
	return self;
}


- (GrowlPluginPreferencePane *) preferencePane {
	if (!_preferencePane)
		_preferencePane = [[GrowlSMSPrefs alloc] initWithBundle:[NSBundle bundleForClass:[self class]]];
	return _preferencePane;
}

- (NSDictionary*)upgradeConfigDict:(NSDictionary*)stored toConfigID:(NSString*)configID {
	NSString *password = [GrowlKeychainUtilities passwordForServiceName:keychainServiceName accountName:keychainAccountName];
	[GrowlKeychainUtilities removePasswordForService:keychainServiceName accountName:keychainAccountName];
	[GrowlKeychainUtilities setPassword:password forService:keychainServiceName accountName:configID];
	return stored;
}

- (void)removeConfiguration:(NSDictionary *)config forID:(NSString *)configID {
	[GrowlKeychainUtilities removePasswordForService:keychainServiceName accountName:configID];	
}

- (void)dispatchNotification:(NSDictionary *)noteDict withConfiguration:(NSDictionary *)configuration {
	NSString	*accountNameValue = [configuration valueForKey:accountNameKey];
	NSString	*apiIDValue = [configuration valueForKey:accountAPIIDKey];
	NSString	*destinationNumberValue = [configuration valueForKey:destinationNumberKey];

	if (!(destinationNumberValue.length && apiIDValue.length && accountNameValue.length)) {
		NSLog(@"SMS display: Cannot send SMS - not enough details in preferences.");
		return;
	}

	NSString *title = noteDict[GROWL_NOTIFICATION_TITLE];
	NSString *desc = noteDict[GROWL_NOTIFICATION_DESCRIPTION];

	//	Fetch the SMS password from the keychain
	NSString *password = [GrowlKeychainUtilities passwordForServiceName:keychainServiceName accountName:[configuration valueForKey:GROWL_PLUGIN_CONFIG_ID]];

	NSString *localHostName = [NSHost currentHost].name;
	NSString *smsSendCommand = [[NSString alloc] initWithFormat:
		@"<clickAPI><sendMsg><api_id>%@</api_id><user>%@</user><password>%@</password><to>+%@</to><text>(%@) %@ (Growl from %@)</text><from>Growl</from></sendMsg></clickAPI>",
		apiIDValue,
		accountNameValue,
		password,
		destinationNumberValue,
		title,
		desc,
		localHostName];

//	NSLog(@"SMS Display...  %@" , smsSendCommand);
	[self sendXMLCommand:smsSendCommand];

	//	Check credit balance.
	NSString *checkBalanceCommand = [[NSString alloc] initWithFormat:
		@"<clickAPI><getBalance><api_id>%@</api_id><user>%@</user><password>%@</password></getBalance></clickAPI>",
		apiIDValue,
		accountNameValue,
		password];

	[self sendXMLCommand:checkBalanceCommand];
}


#pragma mark -
#pragma mark Accessors

- (NSData *) responseData {
	return responseData;
}

- (void) setResponseData:(NSData *)newResponseData {
	responseData = newResponseData;

//	NSLog(@"SMS display: responseData:  %@", responseData);
}


#pragma mark -
#pragma mark Instance Methods


/*
 <clickAPI>
	 <sendMsg>
		 <api_id>your_api_id</api_id>
		 <user>your_user_name</user>
		 <password>your_pass</password>
		 <to>+12343455667</to>
		 <text>Test text message.</text>
		 <from>Growl</from>
	 </sendMsg>
 </clickAPI>


 API URL:
 ==========
 https://api.clickatell.com/xml/xml
 <input name="data" type="text" value="<clickAPI>$your_xml_data</clickAPI>">

 //	To do - use the unicode option - when needed - although, it halves the length of SMS we can send.

 */
- (void) sendXMLCommand:(NSString *)commandString {
	NSString			*dataString = [NSString stringWithFormat:@"data=%@", commandString];
	NSData              *postData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
	NSURL               *clickatellURL = [NSURL URLWithString:@"https://api.clickatell.com/xml/xml"];
	NSMutableURLRequest	*post = [[NSMutableURLRequest alloc] initWithURL:clickatellURL];
	NSString            *contentLength = [NSString stringWithFormat:@"%lu", postData.length];

//	NSLog(@"SMS display: Sending data: %@", postData);

	[post addValue:(NSString *)contentLength forHTTPHeaderField: @"Content-Length"];
	post.HTTPMethod = @"POST";
	post.HTTPBody = (NSData *)postData;
	[commandQueue addObject:post];

	[self processQueue];
}


- (void) processQueue {
	// NSLog(@"SMS display: Processing HTTP Command Queue");
	if (!commandQueue.count) {
		// NSLog(@"SMS display: Queue is empty...");
		return;
	}

	if (!waitingForResponse) {
		waitingForResponse = YES;
        // NSLog(@"SMS display: Beginning Command Request Connection...");
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:[commandQueue objectAtIndex:0U]
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            if (error == nil)
            {
                self.responseData = data;
                [self handleResponse];
            }
            else
            {
                NSLog(@"SMS display: Connection to SMS Web API failed: (%@)", error.localizedDescription);
            }

            [self connectionDidRespond];
        }];
        
        [task resume];
	} else {
		NSLog(@"SMS display: Holding request in queue - we are still waiting for an existing command's resonse..");
	}
}


- (void) connectionDidRespond {
//	NSLog(@"SMS display: Request/Response transaction complete...");
	waitingForResponse = NO;
	[commandQueue removeObjectAtIndex:0U];
	[self processQueue];
}

- (void) handleResponse {
	responseParser = [[NSXMLParser alloc] initWithData:self.responseData];
	responseParser.delegate = self;
	[responseParser setShouldResolveExternalEntities:YES];
	[responseParser parse]; // return value not used
							// if not successful, delegate is informed of error}
}


#pragma mark -
#pragma mark NSXMLParser Delegate methods:

- (void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	if ([elementName isEqualToString:@"clickAPI"]) {
//		NSLog(@"SMS display: Found the clickAPI element in the response.  That means we got the HTTP part right.");
	} else if ([elementName isEqualToString:@"xmlErrorResp"]) {
		NSLog(@"SMS display: Oh Noes! we got an error back from clickatell - we passed them a bad XML request...");
	} else if ([elementName isEqualToString:@"fault"]) {
		NSLog(@"SMS display: Here comes the fault:...");
	} else if ([elementName isEqualToString:@"getBalanceResp"]) {
//		NSLog(@"SMS display: Here comes the Balance response:...");
		inBalanceResponseElement = YES;
	} else if ([elementName isEqualToString:@"ok"]) {
//		NSLog(@"SMS display: Command Success.");
		if (inBalanceResponseElement) {
//			NSLog(@"SMS display: Here comes the Balance value:...");
		}
	} else if ([elementName isEqualToString:@"sendMsgResp"]) {
//		NSLog(@"SMS display: Here comes the Message Send response:...");
		inMessageSendResponseElement = YES;
	}
}


- (void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if (!xmlHoldingStringValue)
		xmlHoldingStringValue = [[NSMutableString alloc] initWithCapacity:50];
	[xmlHoldingStringValue appendString:string];
}


- (void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	if (   [elementName isEqualToString:@"clickAPI"]
		|| [elementName isEqualToString:@"xmlErrorResp"]) {
		// nothing to do
		return;
	} else if ([elementName isEqualToString:@"getBalanceResp"]) {
		inBalanceResponseElement = NO;
		xmlHoldingStringValue = nil;
	} else if ([elementName isEqualToString:@"sendMsgResp"]) {
		inMessageSendResponseElement = NO;
		xmlHoldingStringValue = nil;
	} else if ([elementName isEqualToString:@"fault"]) {
		NSLog(@"SMS display: The fault was: %@" , [xmlHoldingStringValue stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] );
		xmlHoldingStringValue = nil;
	} else if ([elementName isEqualToString:@"ok"]) {
		if (inBalanceResponseElement) {
			creditBalance = [xmlHoldingStringValue stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]].floatValue;
			NSLog(@"SMS display: Your Balance is: %4.1f 'credits'" , creditBalance);
			xmlHoldingStringValue = nil;
		}
	} else if ([elementName isEqualToString:@"apiMsgId"]) {
		if (inMessageSendResponseElement) {
			NSLog(@"SMS display: Your SMS Message has been sent by Clickatell (messageId: %@)" , [xmlHoldingStringValue stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]);
			xmlHoldingStringValue = nil;
		}
	} else if ([elementName isEqualToString:@"sequence_no"]) {
		if (inMessageSendResponseElement) {
//			NSLog(@"SMS display: sequence_no: %@" , [xmlHoldingStringValue stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]);
			xmlHoldingStringValue = nil;
		}
	} else {
		NSLog(@"SMS display: unknown XML element: %@", elementName);
	}
}

- (void) parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	NSLog(@"SMS display: Error Parsing XML response from SMS Gateway - %i, Description: %@, Line: %i, Column: %i",	(int)parseError.code,
		  parser.parserError.localizedDescription,
		  (int)parser.lineNumber,
		  (int)parser.columnNumber);
}

@end
