#import <Foundation/Foundation.h>
#import "PRAPIKey.h"

@class PRValidator;
@protocol PRValidatorDelegate <NSObject>
- (void)validator:(PRValidator *)validator didValidateApiKey:(PRAPIKey *)apiKey;
- (void)validator:(PRValidator *)validator didInvalidateApiKey:(PRAPIKey *)apiKey;
- (void)validator:(PRValidator *)validator didFailWithError:(NSError *)error forApiKey:(PRAPIKey *)apiKey;
@end

@interface PRValidator : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDelegate:(id<PRValidatorDelegate>)delegate NS_DESIGNATED_INITIALIZER;
@property (nonatomic, unsafe_unretained, readonly) id<PRValidatorDelegate> delegate;

- (void)validateApiKey:(PRAPIKey *)apiKey;
- (BOOL)isValidatingApiKey:(PRAPIKey *)apiKey;

@end
