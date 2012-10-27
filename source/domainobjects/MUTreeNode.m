//
// MUTreeNode.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUTreeNode.h"

@interface MUTreeNode ()

- (void) _postWorldsDidChangeNotification;

@end

#pragma mark -

@implementation MUTreeNode

@synthesize children = _children;
@dynamic icon, isLeaf, uniqueIdentifier;

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

#pragma mark - Properties

- (NSImage *) icon
{
  return nil;
}

- (BOOL) isLeaf
{
  return self.children.count == 0;
}

- (NSString *) uniqueIdentifier
{
  NSMutableString *result = [NSMutableString stringWithString: @"treenode:"];
  NSArray *tokens = [self.name componentsSeparatedByString: @" "];
  
  if (tokens.count > 0)
  {
    [result appendFormat: @"%@", [tokens[0] lowercaseString]];
    
    for (NSUInteger i = 1; i < tokens.count; i++)
      [result appendFormat: @".%@", [tokens[i] lowercaseString]];
  }
  return result;
}

#pragma mark - Properties for children

- (NSUInteger) countOfChildren
{
  return _children.count;
}

- (NSTreeNode *) objectInChildrenAtIndex: (NSUInteger) index
{
  return _children[index];
}

- (NSArray *) childrenAtIndexes: (NSIndexSet *) indexSet
{
  return [_children objectsAtIndexes: indexSet];
}

- (void) getChildren: (__unsafe_unretained id *) objects range: (NSRange) range
{
  [_children getObjects: objects range: range];
}

- (void) insertObject: (MUTreeNode *) object inChildrenAtIndex: (NSUInteger) index
{
  object.parent = self;
  _children[index] = object;
}

- (void) insertChildren: (NSArray *) objects atIndexes: (NSIndexSet *) indexes
{
  for (MUTreeNode *child in objects)
    child.parent = self;
  
  [_children insertObjects: objects atIndexes: indexes];
}

- (void) removeObjectFromChildrenAtIndex: (NSUInteger) index
{
  ((MUTreeNode *) _children[index]).parent = nil;
  [_children removeObjectAtIndex: index];
}

- (void) removeChildrenAtIndexes: (NSIndexSet *) indexes
{
  NSArray *childrenAtIndexes = [_children objectsAtIndexes: indexes];
  
  for (MUTreeNode *child in childrenAtIndexes)
    child.parent = nil;
  
  [_children removeObjectsAtIndexes: indexes];
}

- (void) replaceObjectInChildrenAtIndex: (NSUInteger) index withObject: (MUTreeNode *) object
{
  ((MUTreeNode *) _children[index]).parent = nil;
  object.parent = self;
  _children[index] = object;
}

- (void) replaceChildrenAtIndexes: (NSIndexSet *) indexes withChildren: (NSArray *) objects
{
  [_children replaceObjectsAtIndexes: indexes withObjects: objects];
}

#pragma mark - Actions

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

#pragma mark - Array-like accessors for children

- (void) addChild: (MUTreeNode *) child
{
  if ([self containsChild: child])
    return;
  
  [self willChangeValueForKey: @"children"];
  child.parent = self;
  [self.children addObject: child];
  [self didChangeValueForKey: @"children"];
  
  [self _postWorldsDidChangeNotification];
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

- (void) removeChild: (MUTreeNode *) child
{
  [self willChangeValueForKey: @"children"];
  child.parent = nil;
  [self.children removeObject: child];
  [self didChangeValueForKey: @"children"];
  
  [self _postWorldsDidChangeNotification];
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
    
    [self _postWorldsDidChangeNotification];
    break;
  }
}

#pragma mark - Private methods

- (void) _postWorldsDidChangeNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUWorldsDidChangeNotification
                                                      object: self];
}

@end
