//
// MUTreeNode.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUTreeNode.h"

@interface MUTreeNode ()

- (void) postWorldsDidChangeNotification;

@end

#pragma mark -

@implementation MUTreeNode

@dynamic icon, isLeaf;

- (id) initWithName: (NSString *) newName children: (NSArray *) newChildren
{
  if (!(self = [super init]))
    return nil;
  
  _name = [newName copy];
  _parent = nil;
  
  if (newChildren)
    _children = [newChildren mutableCopy];
  else
    _children = [[NSMutableArray alloc] init];

  return self;
}

- (id) init
{
  return [self initWithName: @"Empty node" children: nil];
}

- (NSImage *) icon
{
  return nil;
}

/*
- (NSUInteger) count
{
  return children.count;
}
 */

- (BOOL) isLeaf
{
  return self.children.count == 0;
}

- (void) recursivelyUpdateParentsWithParentNode: (MUTreeNode *) topParentNode
{
  self.parent = topParentNode;
  
  for (MUTreeNode *node in self.children)
  {
    if (node.isLeaf)
      node.parent = self;
    else
      [node recursivelyUpdateParentsWithParentNode: self];
  }
}

#pragma mark - Array-like accessors for players

- (void) addChild: (MUTreeNode *) child
{
  if ([self containsChild: child])
    return;
  
  [self willChangeValueForKey: @"children"];
  child.parent = self;
  [self.children addObject: child];
  [self didChangeValueForKey: @"children"];
  
  [self postWorldsDidChangeNotification];
}

- (BOOL) containsChild: (MUTreeNode *) child
{
  return [self.children containsObject: child];
}

- (NSUInteger) indexOfChild: (MUTreeNode *) child
{
  for (NSUInteger i = 0; i < self.children.count; i++)
  {
    if (child == self.children[i])
      return i;
  }
  
  return NSNotFound;
}

- (void) insertObject: (MUTreeNode *) child inChildrenAtIndex: (NSUInteger) childIndex
{
  [self willChangeValueForKey: @"children"];
  child.parent = self;
  [self.children insertObject: child atIndex: childIndex];
  [self didChangeValueForKey: @"children"];
  
  [self postWorldsDidChangeNotification];
}

- (void) removeObjectFromChildrenAtIndex: (NSUInteger) childIndex
{
  [self willChangeValueForKey: @"children"];
  ((MUTreeNode *) self.children[childIndex]).parent = nil;
  [self.children removeObjectAtIndex: childIndex];
  [self didChangeValueForKey: @"children"];
  
  [self postWorldsDidChangeNotification];
}

- (void) removeChild: (MUTreeNode *) child
{
  [self willChangeValueForKey: @"children"];
  child.parent = nil;
  [self.children removeObject: child];
  [self didChangeValueForKey: @"children"];
  
  [self postWorldsDidChangeNotification];
}

- (void) replaceChild: (MUTreeNode *) oldChild withChild: (MUTreeNode *) newChild
{
  for (NSUInteger i = 0; i < self.children.count; i++)
  {
    MUTreeNode *node = self.children[i];
    
    if (node != oldChild)
      continue;
    
    [self willChangeValueForKey: @"children"];
    newChild.parent = self;
    oldChild.parent = nil;
    self.children[i] = newChild;
    [self didChangeValueForKey: @"children"];
    
    [self postWorldsDidChangeNotification];
    break;
  }
}

#pragma mark - Private methods

- (void) postWorldsDidChangeNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUWorldsDidChangeNotification
                                                      object: self];
}

@end
