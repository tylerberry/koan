//
// MUConnectionWindowControllerRegistry.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUConnectionWindowControllerRegistry.h"

@implementation MUConnectionWindowControllerRegistry

+ (MUConnectionWindowControllerRegistry *) defaultRegistry
{
  static MUConnectionWindowControllerRegistry *_defaultRegistry = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ _defaultRegistry = [[MUConnectionWindowControllerRegistry alloc] init]; });
  
  return _defaultRegistry;
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  _connectionWindowControllers = [[NSMutableArray alloc] init];
  
  return self;
}

@end
