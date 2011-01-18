//
// MUTreeNode.m
//
// Copyright (c) 2010 3James Software.
//

#import "MUTreeNode.h"

@interface MUTreeNode (Private)

- (void) postWorldsDidChangeNotification;

@end

#pragma mark -

@implementation MUTreeNode

@synthesize children, name, parent;
@dynamic isLeaf;

- (id) initWithName: (NSString *) newName children: (NSArray *) newChildren
{
  if (!(self = [super init]))
    return nil;
  
  name = [newName copy];
  
  if (newChildren)
    children = [newChildren mutableCopy];
  else
    children = [[NSMutableArray alloc] init];

  return self;
}

- (id) init
{
  return [self initWithName: @"Empty node" children: nil];
}

- (void) dealloc
{
  [children release];
  [name release];
  [super dealloc];
}

/*
- (NSUInteger) count
{
  return [children count];
}
 */

- (BOOL) isLeaf
{
  return [children count] == 0;
}

- (void) recursivelyUpdateParentsWithParentNode: (MUTreeNode *) topParentNode
{
  self.parent = topParentNode;
  
  for (MUTreeNode *node in children)
  {
    if (!node.isLeaf)
      [node recursivelyUpdateParentsWithParentNode: self];
  }
}

#pragma mark -
#pragma mark Array-like accessors for players

- (void) addChild: (MUTreeNode *) child
{
  if ([self containsChild: child])
    return;
  
  [self willChangeValueForKey: @"children"];
  child.parent = self;
  [children addObject: child];
  [self didChangeValueForKey: @"children"];
  
  [self postWorldsDidChangeNotification];
}

- (BOOL) containsChild: (MUTreeNode *) child
{
  return [self.children containsObject: child];
}

- (NSUInteger) indexOfChild: (MUTreeNode *) child
{
  for (NSUInteger i = 0; i < [self.children count]; i++)
  {
    if (child == [self.children objectAtIndex: i])
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
  ((MUTreeNode *) [self.children objectAtIndex: childIndex]).parent = nil;
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
  for (unsigned i = 0; i < [self.children count]; i++)
  {
    MUTreeNode *node = [self.children objectAtIndex: i];
    
    if (node != oldChild)
      continue;
    
    [self willChangeValueForKey: @"children"];
    newChild.parent = self;
    oldChild.parent = nil;
    [self.children replaceObjectAtIndex: i withObject: newChild];
    [self didChangeValueForKey: @"children"];
    
    [self postWorldsDidChangeNotification];
    break;
  }
}

@end

#pragma mark -

@implementation MUTreeNode (Private)

- (void) postWorldsDidChangeNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUWorldsDidChangeNotification
                                                      object: self];
}

@end
