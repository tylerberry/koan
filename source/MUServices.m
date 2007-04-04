//
// MUServices.m
//
// Copyright (c) 2007 3James Software.
//

#import "MUServices.h"

@implementation MUServices

+ (MUProfileRegistry *) profileRegistry
{
  return [MUProfileRegistry defaultRegistry];
}

+ (MUWorldRegistry *) worldRegistry
{
  return [MUWorldRegistry defaultRegistry];
}

@end
