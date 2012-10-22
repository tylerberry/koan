//
// MUProfilesSection.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUProfilesSection.h"
#import "MUWorldRegistry.h"

@implementation MUProfilesSection

- (id) initWithName: (NSString *) newName
{
  if (!(self = [super initWithName: newName children: nil]))
    return nil;
  
  return self;
}

- (NSMutableArray *) children
{
  return [MUWorldRegistry defaultRegistry].mutableWorlds;
}

- (void) setChildren: (NSMutableArray *) newChildren
{
  [MUWorldRegistry defaultRegistry].mutableWorlds = newChildren;
}

- (BOOL) isLeaf
{
  return [MUWorldRegistry defaultRegistry].count == 0;
}

- (NSString *) uniqueIdentifier
{
  return @"profilessection:";
}

@end
