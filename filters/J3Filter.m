//
// J3Filter.m
//
// Copyright (c) 2010 3James Software.
//

#import "J3Filter.h"

@implementation J3Filter

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
