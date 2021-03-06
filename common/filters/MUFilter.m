//
// MUFilter.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUFilter.h"

@implementation MUFilter

+ (instancetype) filter
{
  return [[self alloc] init];
}

- (NSAttributedString *) filterCompleteLine: (NSAttributedString *) attributedString
{
  @throw [NSException exceptionWithName: @"SubclassResponsibility"
                                 reason: @"subclass failed to implement -[filterCompleteLine:]"
                               userInfo: nil];
}

- (NSAttributedString *) filterPartialLine: (NSAttributedString *) attributedString
{
  @throw [NSException exceptionWithName: @"SubclassResponsibility"
                                 reason: @"subclass failed to implement -[filterPartialLine:]"
                               userInfo: nil];
}

@end
