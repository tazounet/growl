//
//  GrowlServerViewController.h
//  Growl
//
//  Created by Daniel Siemer on 11/10/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlPrefsViewController.h"

@class GNTPForwarder, GNTPSubscriptionController;

@interface GrowlServerViewController : GrowlPrefsViewController

@property (nonatomic, weak) GNTPForwarder *forwarder;
@property (nonatomic, weak) GNTPSubscriptionController *subscriptionController;
@property (nonatomic, weak) IBOutlet NSTableColumn *serviceNameColumn;
@property (nonatomic, weak) IBOutlet NSTableColumn *servicePasswordColumn;
@property (nonatomic, weak) IBOutlet NSTableView *networkTableView;
@property (nonatomic, weak) IBOutlet NSTableView *subscriptionsTableView;
@property (nonatomic, weak) IBOutlet NSTableView *subscriberTableView;
@property (nonatomic, weak) IBOutlet NSArrayController *subscriptionArrayController;
@property (nonatomic, weak) IBOutlet NSArrayController *subscriberArrayController;
@property (nonatomic, weak) IBOutlet NSTabView *networkConnectionTabView;

@property (nonatomic, strong) NSString *listenForIncomingNoteLabel;
@property (nonatomic, strong) NSString *serverPasswordLabel;
@property (nonatomic, strong) NSString *ipAddressesLabel;
@property (nonatomic, strong) NSString *forwardingTabTitle;
@property (nonatomic, strong) NSString *subscriptionsTabTitle;
@property (nonatomic, strong) NSString *subscribersTabTitle;
@property (nonatomic, strong) NSString *bonjourDiscoveredLabel;
@property (nonatomic, strong) NSString *manualEntryLabel;
@property (nonatomic, strong) NSString *firewallLabel;

@property (nonatomic, strong) NSString *forwardEnableCheckboxLabel;
@property (nonatomic, strong) NSString *subscriberEnableCheckboxLabel;
@property (nonatomic, strong) NSString *useColumnTitle;
@property (nonatomic, strong) NSString *computerColumnTitle;
@property (nonatomic, strong) NSString *passwordColumnTitle;
@property (nonatomic, strong) NSString *validColumnTitle;

@property (nonatomic) int currentServiceIndex;

@property (nonatomic, strong) NSString *networkAddressString;

- (void)updateAddresses:(NSNotification*)note;
- (void)showNetworkConnectionTab:(NSUInteger)tab;
- (IBAction)removeSelectedForwardDestination:(id)sender;
- (IBAction)newManualForwader:(id)sender;

- (IBAction)newManualSubscription:(id)sender;
- (IBAction)removeSelectedSubscription:(id)sender;

- (IBAction)removeSelectedSubscriber:(id)sender;

@end
