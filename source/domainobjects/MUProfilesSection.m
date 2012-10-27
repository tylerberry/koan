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
  
  [[MUWorldRegistry defaultRegistry] addObserver: self forKeyPath: @"worlds" options: 0 context: nil];
  
  return self;
}

- (void) dealloc
{
  [[MUWorldRegistry defaultRegistry] removeObserver: self forKeyPath: @"worlds"];
}

- (void) observeValueForKeyPath: (NSString *) keyPath
                       ofObject: (id) object
                         change: (NSDictionary *) changeDictionary
                        context: (void *) context
{
  if (object == [MUWorldRegistry defaultRegistry] && [keyPath isEqualToString: @"worlds"])
  {
    [self willChangeValueForKey: @"children"];
    [self didChangeValueForKey: @"children"];
    return;
  }
  [super observeValueForKeyPath: keyPath ofObject: object change: changeDictionary context: context];
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
  return [MUWorldRegistry defaultRegistry].worlds.count == 0;
}

- (NSString *) uniqueIdentifier
{
  return @"profilessection:";
}

@end
