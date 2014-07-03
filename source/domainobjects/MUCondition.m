//
// MUCondition.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUCondition.h"

@implementation MUCondition

- (instancetype) initWithName: (NSString *) name
{
  if (!(self = [super init]))
    return nil;

  _name = [name copy];

  return self;
}

@end
