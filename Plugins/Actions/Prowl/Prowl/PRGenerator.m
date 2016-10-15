#import "PRGenerator.h"
#import "PRServerError.h"

@interface PRGenerator()
@property (nonatomic, copy, readwrite) NSString *providerKey;
@property (nonatomic, unsafe_unretained, readwrite) id<PRGeneratorDelegate> delegate;
@property (nonatomic, copy, readwrite) NSString *token;
@property (nonatomic, copy, readwrite) NSString *tokenURL;
@property (nonatomic, strong, readwrite) PRAPIKey *apiKey;
@end

@implementation PRGenerator
@synthesize providerKey = _providerKey;
@synthesize delegate = _delegate;
@synthesize token = _token;
@synthesize tokenURL = _tokenURL;
@synthesize apiKey = _apiKey;

- (instancetype)initWithProviderKey:(NSString *)providerKey
				 delegate:(id<PRGeneratorDelegate>)delegate
{
	self = [super init];
	if(self) {
		self.providerKey = providerKey;
		self.delegate = delegate;
	}
	return self;
}


- (NSString *)encodedStringForString:(NSString *)string
{
    NSCharacterSet *queryKVSet = [NSCharacterSet
                                  characterSetWithCharactersInString:@";/?:@&=+$"
                                  ].invertedSet;
    
    NSString *encodedString = [string stringByAddingPercentEncodingWithAllowedCharacters:queryKVSet];
	
	return encodedString;
}

- (NSXMLElement *)retrieveElementFromData:(NSData *)data error:(NSError **)error
{
	NSXMLElement *retrieveElement = nil;
	NSError *xmlError = nil;
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithData:data options:0 error:&xmlError];
	if(document) {
		NSArray *retrieveElements = [document.rootElement elementsForName:@"retrieve"];
		if(!retrieveElements.count) {
			if(error)
				*error = [PRServerError serverErrorWithStatusCode:-1];
		} else {
			retrieveElement = retrieveElements.lastObject;
		}
	} else {
		if(error)
			*error = xmlError;
	}
	return retrieveElement;
}

- (void)fetchToken
{
	NSMutableString *fetchURLString = [NSMutableString stringWithString:@"https://api.prowlapp.com/publicapi/retrieve/token"];
	[fetchURLString appendFormat:@"?providerkey=%@", [self encodedStringForString:self.providerKey]];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fetchURLString]
														   cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
													   timeoutInterval:300.0f];
	
	request.HTTPMethod = @"GET";
	
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        if(!data) {
            [self.delegate generator:self didFailWithError:error];
            return;
        }
        
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        
        //NSLog(@"Got back XML: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
        
        if(statusCode == 200) {
            NSXMLElement *retrieveElement = [self retrieveElementFromData:data error:&error];
            if(retrieveElement) {
                NSXMLNode *tokenNode = [retrieveElement attributeForName:@"token"];
                NSXMLNode *urlNode = [retrieveElement attributeForName:@"url"];
                
                self.token = tokenNode.stringValue;
                [self.delegate generator:self didFetchTokenURL:urlNode.stringValue];
            } else {
                [self.delegate generator:self didFailWithError:error];
            }
        } else {
            [self.delegate generator:self didFailWithError:[PRServerError serverErrorWithStatusCode:statusCode]];
        }
    }];

    [dataTask resume];
}

- (void)fetchApiKey
{
	NSMutableString *fetchURLString = [NSMutableString stringWithString:@"https://api.prowlapp.com/publicapi/retrieve/apikey"];
	[fetchURLString appendFormat:@"?providerkey=%@", [self encodedStringForString:self.providerKey]];
	[fetchURLString appendFormat:@"&token=%@", [self encodedStringForString:self.token]];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fetchURLString]
														   cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
													   timeoutInterval:300.0f];
	
	request.HTTPMethod = @"GET";
	
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        if(!data) {
            [self.delegate generator:self didFailWithError:error];
            return;
        }
        
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        
        NSLog(@"Got back XML: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        
        if(statusCode == 200) {
            NSXMLElement *retrieveElement = [self retrieveElementFromData:data error:&error];
            if(retrieveElement) {
                NSXMLNode *apikeyNode = [retrieveElement attributeForName:@"apikey"];
                
                self.apiKey = [[PRAPIKey alloc] init];
                self.apiKey.enabled = YES;
                self.apiKey.apiKey = apikeyNode.stringValue;
                self.apiKey.validated = YES; // after so the change doesn't reset it
                
                [self.delegate generator:self didFetchApiKey:self.apiKey];
            } else {
                [self.delegate generator:self didFailWithError:error];
            }
        } else {
            [self.delegate generator:self didFailWithError:[PRServerError serverErrorWithStatusCode:statusCode]];
        }
    }];

    [dataTask resume];
}

@end
