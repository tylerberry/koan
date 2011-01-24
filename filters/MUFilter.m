//
// MUFilter.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUFilter.h"

@implementation MUFilter

+ (id) filter
{
  return [[[self alloc] init] autorelease];
}

- (NSAttributedString *) filter: (NSAttributedString *) string
{
  @throw [NSException exceptionWithName: @"SubclassResponsibility"
                                 reason: @"Subclass failed to implement -[filter:]"
                               userInfo: nil];
}

@end
