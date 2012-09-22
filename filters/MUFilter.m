//
// MUFilter.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUFilter.h"

@implementation MUFilter

+ (id) filter
{
  return [[self alloc] init];
}

- (NSAttributedString *) filter: (NSAttributedString *) string
{
  @throw [NSException exceptionWithName: @"SubclassResponsibility"
                                 reason: @"subclass failed to implement -[filter:]"
                               userInfo: nil];
}

@end
