//
// MUFilterTestCase.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUFilterQueue.h"

@interface MUFilterTestCase : XCTestCase

@property (strong) MUFilterQueue *queue;

- (void) assertInput: (NSString *) input hasOutput: (NSString *) output;
- (void) assertInput: (NSString *) input
           hasOutput: (NSString *) output
             message: (NSString *) message;
- (NSMutableAttributedString *) constructAttributedStringForString: (NSString *) string;

@end
