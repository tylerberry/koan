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
  return [MUWorldRegistry defaultRegistry].mutableWorlds;
}

- (void) setChildren: (NSMutableArray *) newChildren
{
  [MUWorldRegistry defaultRegistry].mutableWorlds = newChildren;
}

- (NSUInteger) countOfChildren
{
  return [MUWorldRegistry defaultRegistry].mutableWorlds.count;
}

- (NSTreeNode *) objectInChildrenAtIndex: (NSUInteger) index
{
  return [MUWorldRegistry defaultRegistry].mutableWorlds[index];
}

- (NSArray *) childrenAtIndexes: (NSIndexSet *) indexSet
{
  return [[MUWorldRegistry defaultRegistry].mutableWorlds objectsAtIndexes: indexSet];
}

- (void) getChildren: (__unsafe_unretained id *) objects range: (NSRange) range
{
  [[MUWorldRegistry defaultRegistry].mutableWorlds getObjects: objects range: range];
}

- (void) insertObject: (MUTreeNode *) object inChildrenAtIndex: (NSUInteger) index
{
  object.parent = self;
  [[MUWorldRegistry defaultRegistry].mutableWorlds insertObject: object atIndex: index];
}

- (void) insertChildren: (NSArray *) objects atIndexes: (NSIndexSet *) indexes
{
  for (MUTreeNode *child in objects)
    child.parent = self;
  
  [[MUWorldRegistry defaultRegistry].mutableWorlds insertObjects: objects atIndexes: indexes];
}

- (void) removeObjectFromChildrenAtIndex: (NSUInteger) index
{
  ((MUTreeNode *) [MUWorldRegistry defaultRegistry].mutableWorlds[index]).parent = nil;
  [[MUWorldRegistry defaultRegistry].mutableWorlds removeObjectAtIndex: index];
}

- (void) removeChildrenAtIndexes: (NSIndexSet *) indexes
{
  NSArray *childrenAtIndexes = [[MUWorldRegistry defaultRegistry].mutableWorlds objectsAtIndexes: indexes];
  
  for (MUTreeNode *child in childrenAtIndexes)
    child.parent = nil;
  
  [[MUWorldRegistry defaultRegistry].mutableWorlds removeObjectsAtIndexes: indexes];
}

- (void) replaceObjectInChildrenAtIndex: (NSUInteger) index withObject: (MUTreeNode *) object
{
  ((MUTreeNode *) [MUWorldRegistry defaultRegistry].mutableWorlds[index]).parent = nil;
  object.parent = self;
  [MUWorldRegistry defaultRegistry].mutableWorlds[index] = object;
}

- (void) replaceChildrenAtIndexes: (NSIndexSet *) indexes withChildren: (NSArray *) objects
{
  [[MUWorldRegistry defaultRegistry].mutableWorlds replaceObjectsAtIndexes: indexes withObjects: objects];
}

@end
