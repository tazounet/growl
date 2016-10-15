#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class PRWebViewWindowController;
@protocol PRWebViewWindowControllerDelegate <NSObject>
- (void)webView:(PRWebViewWindowController *)webView didFailWithError:(NSError *)error;
- (void)webViewDidSucceed:(PRWebViewWindowController *)webView;
@end

@interface PRWebViewWindowController : NSWindowController
@property (weak) IBOutlet WebView *webView;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithWindow:(NSWindow *)window NS_UNAVAILABLE;

- (instancetype)initWithURL:(NSString *)retrieveURL
		 delegate:(id<PRWebViewWindowControllerDelegate>)delegate;

@property (nonatomic, unsafe_unretained, readonly) id<PRWebViewWindowControllerDelegate> delegate;
@property (nonatomic, strong, readonly) NSString *retrieveURL;

@end
