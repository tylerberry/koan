//
// MUAcknowledgementsController.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

@interface MUAcknowledgementsController : NSWindowController

- (id) init;

- (IBAction) openGrowlWebPage: (id) sender;
- (IBAction) openOpenSSLWebPage: (id) sender;
- (IBAction) openSparkleWebPage: (id) sender;
- (IBAction) openUKPrefsPanelWebPage: (id) sender;

@end
