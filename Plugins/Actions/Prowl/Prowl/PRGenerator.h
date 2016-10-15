#import <Foundation/Foundation.h>
#import "PRDefines.h"
#import "PRAPIKey.h"

@class PRGenerator;

@protocol PRGeneratorDelegate <NSObject>
- (void)generator:(PRGenerator *)generator didFetchTokenURL:(NSString *)retrieveURL;
- (void)generator:(PRGenerator *)generator didFetchApiKey:(PRAPIKey *)apiKey;
- (void)generator:(PRGenerator *)generator didFailWithError:(NSError *)error;
@end

@interface PRGenerator : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithProviderKey:(NSString *)providerKey
				 delegate:(id<PRGeneratorDelegate>)delegate NS_DESIGNATED_INITIALIZER;
@property (nonatomic, copy, readonly) NSString *providerKey;
@property (nonatomic, unsafe_unretained, readonly) id<PRGeneratorDelegate> delegate;

- (void)fetchToken;
@property (nonatomic, copy, readonly) NSString *token;
@property (nonatomic, copy, readonly) NSString *tokenURL;

- (void)fetchApiKey;
@property (nonatomic, strong, readonly) PRAPIKey *apiKey;

@end
