//
// MUFilterTestCase.h
//
// Copyright (c) 2011 3James Software.
//

#import <J3Testing/J3TestCase.h>

#import "MUFilterQueue.h"

@interface MUFilterTestCase : J3TestCase
{
  MUFilterQueue *queue;
}

- (void) assertInput: (NSString *) input hasOutput: (NSString *) output;
- (void) assertInput: (NSString *) input
           hasOutput: (NSString *) output
             message: (NSString *) message;
- (NSMutableAttributedString *) constructAttributedStringForString: (NSString *) string;

@end
