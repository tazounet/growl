#import "PRValidator.h"
#import "PRServerError.h"

@interface PRValidator()
@property (nonatomic, unsafe_unretained, readwrite) id<PRValidatorDelegate> delegate;
@property (nonatomic, strong) NSMutableSet *validatingApiKeys;
@end

@implementation PRValidator
@synthesize delegate = _delegate;
@synthesize validatingApiKeys = _validatingApiKeys;

- (instancetype)initWithDelegate:(id<PRValidatorDelegate>)delegate
{
	self = [super init];
	if(self) {
		self.delegate = delegate;
		self.validatingApiKeys = [NSMutableSet set];
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

- (BOOL)isValidatingApiKey:(PRAPIKey *)apiKey
{
	return [self.validatingApiKeys containsObject:apiKey];
}

- (void)validateApiKey:(PRAPIKey *)apiKey
{
	NSMutableString *fetchURLString = [NSMutableString stringWithString:@"https://api.prowlapp.com/publicapi/verify"];
	[fetchURLString appendFormat:@"?apikey=%@", [self encodedStringForString:apiKey.apiKey]];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fetchURLString]
														   cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
													   timeoutInterval:300.0f];
	
	request.HTTPMethod = @"GET";
	
	[self.validatingApiKeys addObject:apiKey];
	
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        //NSLog(@"Response: %@", response);
        
        [self.validatingApiKeys removeObject:apiKey];
        
        if(!data) {
            [self.delegate validator:self
                    didFailWithError:error
                           forApiKey:apiKey];
            return;
        }
        
        //NSLog(@"Got back XML: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
        
        NSXMLDocument *document = [[NSXMLDocument alloc] initWithData:data options:0 error:&error];
        
        if(!document) {
            [self.delegate validator:self
                    didFailWithError:error
                           forApiKey:apiKey];
        }
        
        NSXMLElement *successElement = [[document.rootElement elementsForName:@"success"] lastObject];
        if(successElement) {
            [self.delegate validator:self
                   didValidateApiKey:apiKey];
        } else {
            NSXMLElement *errorElement = [[document.rootElement elementsForName:@"error"] lastObject];
            if(errorElement) {
                NSInteger errorCode = [[[errorElement attributeForName:@"code"] stringValue] integerValue];
                if(errorCode == 401) {
                    [self.delegate validator:self
                         didInvalidateApiKey:apiKey];
                } else {
                    [self.delegate validator:self
                            didFailWithError:[PRServerError serverErrorWithStatusCode:errorCode]
                                   forApiKey:apiKey];
                }
            } else {
                [self.delegate validator:self
                        didFailWithError:[PRServerError serverErrorWithStatusCode:-1]
                               forApiKey:apiKey];
            }
        }
    }];

    [dataTask resume];
}

@end
