#import <GrowlPlugins/GrowlPluginPreferencePane.h>
#import "PRDefines.h"
#import "PRAPIKey.h"

@interface PRPreferencePane : GrowlPluginPreferencePane
@property (nonatomic, strong, readonly) NSMutableArray *apiKeys; // array of PRAPIKey
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSBox *apiKeysBox;

@property (weak) IBOutlet NSBox *sendingToProwlBox;
@property (weak) IBOutlet NSButton *prefixCheckbox;
@property (weak) IBOutlet NSButton *minimumPriorityCheckbox;
@property (weak) IBOutlet NSButton *onlyWhenIdleCheckbox;

@property (nonatomic, assign) BOOL onlyWhenIdle;
@property (nonatomic, assign) BOOL minimumPriorityEnabled;
@property (nonatomic, assign) NSInteger minimumPriority;
@property (nonatomic, assign) BOOL prefixEnabled;
@property (nonatomic, copy) NSString *prefix;

@property (weak) IBOutlet NSButton *addButton;
@property (weak) IBOutlet NSButton *removeButton;
@property (weak) IBOutlet NSButton *generateButton;
@property (weak) IBOutlet NSProgressIndicator *generateProgressIndicator;

- (IBAction)generate:(id)sender;
- (IBAction)add:(id)sender;
- (IBAction)remove:(id)sender;
@end
