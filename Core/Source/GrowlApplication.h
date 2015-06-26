//
//  GrowlApplication.h
//  Growl
//
//  Created by Evan Schoenberg on 5/10/07.
//  Copyright 2007 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GrowlApplication : NSApplication {
	NSTimer *autoreleasePoolRefreshTimer;
}

@property (nonatomic, strong) NSString *appMenuLabel;
@property (nonatomic, strong) NSString *aboutAppLabel;
@property (nonatomic, strong) NSString *preferencesLabel;
@property (nonatomic, strong) NSString *servicesMenuLabel;
@property (nonatomic, strong) NSString *hideAppLabel;
@property (nonatomic, strong) NSString *hideOthersLabel;
@property (nonatomic, strong) NSString *showAllLabel;
@property (nonatomic, strong) NSString *quitAppLabel;

@property (nonatomic, strong) NSString *editMenuLabel;
@property (nonatomic, strong) NSString *undoLabel;
@property (nonatomic, strong) NSString *redoLabel;
@property (nonatomic, strong) NSString *cutLabel;
@property (nonatomic, strong) NSString *theCopyLabel;
@property (nonatomic, strong) NSString *pasteLabel;
@property (nonatomic, strong) NSString *pasteAndMatchLabel;
@property (nonatomic, strong) NSString *deleteLabel;
@property (nonatomic, strong) NSString *selectAllLabel;

@property (nonatomic, strong) NSString *findMenuLabel;
@property (nonatomic, strong) NSString *findLabel;
@property (nonatomic, strong) NSString *findAndReplaceLabel;
@property (nonatomic, strong) NSString *findNextLabel;
@property (nonatomic, strong) NSString *findPreviousLabel;
@property (nonatomic, strong) NSString *useSelectionForFindLabel;
@property (nonatomic, strong) NSString *jumpToSelectionLabel;

@property (nonatomic, strong) NSString *spellingGrammarMenuLabel;
@property (nonatomic, strong) NSString *showSpellingGrammarLabel;
@property (nonatomic, strong) NSString *checkDocumentNowLabel;
@property (nonatomic, strong) NSString *checkSpellingWhileTypingLabel;
@property (nonatomic, strong) NSString *checkGrammarWithSpelling;
@property (nonatomic, strong) NSString *correctSpellingAutomatically;

@property (nonatomic, strong) NSString *substitutionsMenuLabel;
@property (nonatomic, strong) NSString *showSubstitutionsLabel;
@property (nonatomic, strong) NSString *smartCopyPasteLabel;
@property (nonatomic, strong) NSString *smartQuotesLabel;
@property (nonatomic, strong) NSString *smartDashesLabel;
@property (nonatomic, strong) NSString *smartLinksLabel;
@property (nonatomic, strong) NSString *dataDetectorsLabel;
@property (nonatomic, strong) NSString *textReplacementLabel;

@property (nonatomic, strong) NSString *transformationsMenuLabel;
@property (nonatomic, strong) NSString *makeUpperCaseLabel;
@property (nonatomic, strong) NSString *makeLowerCaseLabel;
@property (nonatomic, strong) NSString *capitalizeLabel;

@property (nonatomic, strong) NSString *speechMenuLabel;
@property (nonatomic, strong) NSString *startSpeaking;
@property (nonatomic, strong) NSString *stopSpeaking;

@property (nonatomic, strong) NSString *windowMenuLabel;
@property (nonatomic, strong) NSString *minimizeLabel;
@property (nonatomic, strong) NSString *zoomLabel;
@property (nonatomic, strong) NSString *closeLabel;
@property (nonatomic, strong) NSString *bringAllToFrontLabel;

@property (nonatomic, strong) NSString *helpMenuLabel;
@property (nonatomic, strong) NSString *appHelpLabel;

@end
