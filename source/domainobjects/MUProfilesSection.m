//
// MUProfilesSection.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUProfilesSection.h"
#import "MUWorldRegistry.h"

@implementation MUProfilesSection

- (instancetype) initWithName: (NSString *) newName
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

#pragma mark - Property method implementations

- (BOOL) isLeaf
{
  return [MUWorldRegistry defaultRegistry].worlds.count == 0;
}

- (NSString *) uniqueIdentifier
{
  return @"profilessection:";
}

#pragma mark - Property method implementations - children

- (NSMutableArray *) children
{
  return [MUWorldRegistry defaultRegistry].worlds;
}

- (void) setChildren: (NSMutableArray *) newChildren
{
  [MUWorldRegistry defaultRegistry].worlds = newChildren;
}

- (NSUInteger) countOfChildren
{
  return [[MUWorldRegistry defaultRegistry] mutableArrayValueForKey: @"worlds"].count;
}

- (NSTreeNode *) objectInChildrenAtIndex: (NSUInteger) index
{
  return [[MUWorldRegistry defaultRegistry] mutableArrayValueForKey: @"worlds"][index];
}

- (NSArray *) childrenAtIndexes: (NSIndexSet *) indexSet
{
  return [[[MUWorldRegistry defaultRegistry] mutableArrayValueForKey: @"worlds"] objectsAtIndexes: indexSet];
}

- (void) getChildren: (__unsafe_unretained id *) objects range: (NSRange) range
{
  [[[MUWorldRegistry defaultRegistry] mutableArrayValueForKey: @"worlds"] getObjects: objects range: range];
}

- (void) insertObject: (MUTreeNode *) object inChildrenAtIndex: (NSUInteger) index
{
  object.parent = self;
  [[[MUWorldRegistry defaultRegistry] mutableArrayValueForKey: @"worlds"] insertObject: object atIndex: index];
}

- (void) insertChildren: (NSArray *) objects atIndexes: (NSIndexSet *) indexes
{
  for (MUTreeNode *child in objects)
    child.parent = self;
  
  [[[MUWorldRegistry defaultRegistry] mutableArrayValueForKey: @"worlds"] insertObjects: objects atIndexes: indexes];
}

- (void) removeObjectFromChildrenAtIndex: (NSUInteger) index
{
  ((MUTreeNode *) [MUWorldRegistry defaultRegistry].worlds[index]).parent = nil;
  [[[MUWorldRegistry defaultRegistry] mutableArrayValueForKey: @"worlds"] removeObjectAtIndex: index];
}

- (void) removeChildrenAtIndexes: (NSIndexSet *) indexes
{
  NSArray *childrenAtIndexes = [[MUWorldRegistry defaultRegistry].worlds objectsAtIndexes: indexes];
  
  for (MUTreeNode *child in childrenAtIndexes)
    child.parent = nil;
  
  [[[MUWorldRegistry defaultRegistry] mutableArrayValueForKey: @"worlds"] removeObjectsAtIndexes: indexes];
}

- (void) replaceObjectInChildrenAtIndex: (NSUInteger) index withObject: (MUTreeNode *) object
{
  ((MUTreeNode *) [MUWorldRegistry defaultRegistry].worlds[index]).parent = nil;
  object.parent = self;
  [[MUWorldRegistry defaultRegistry] mutableArrayValueForKey: @"worlds"][index] = object;
}

- (void) replaceChildrenAtIndexes: (NSIndexSet *) indexes withChildren: (NSArray *) objects
{
  [[[MUWorldRegistry defaultRegistry] mutableArrayValueForKey: @"worlds"] replaceObjectsAtIndexes: indexes
                                                                                      withObjects: objects];
}

@end
