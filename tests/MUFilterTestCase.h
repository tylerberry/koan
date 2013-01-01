//
// MUFilterTestCase.h
//
// Copyright (c) 2013 3James Software.
//

#import "J3TestCase.h"

#import "MUFilterQueue.h"

@interface MUFilterTestCase : J3TestCase

@property (strong) MUFilterQueue *queue;

- (void) assertInput: (NSString *) input hasOutput: (NSString *) output;
- (void) assertInput: (NSString *) input
           hasOutput: (NSString *) output
             message: (NSString *) message;
- (NSMutableAttributedString *) constructAttributedStringForString: (NSString *) string;

@end
