#import <Foundation/Foundation.h>

extern NSString *const PRServerErrorDomain;

typedef NS_ENUM(NSInteger, PRStatusCode) {
	PRStatusCodeSuccess = 200,
	PRStatusCodeBadRequest = 400, 
	PRStatusCodeNotAuthorized = 401,
	PRStatusCodeNotAcceptable = 406,
	PRStatusCodeNotApproved = 409,
	PRStatusCodeInternalError = 500,
};

@interface PRServerError : NSError

+ (instancetype)serverErrorWithStatusCode:(NSInteger)statusCode;

@end
