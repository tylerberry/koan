//
// MUTreeNode.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTreeNode.h"

static const int32_t _currentTreeNodeVersion = 1;

static NSMutableDictionary *_uniqueIdentifiers;

@interface MUTreeNode ()
{
  NSString *_uniqueIdentifier;
}

- (NSString *) _createUniqueIdentifier;
- (void) _postWorldsDidChangeNotification;

@end

#pragma mark -

@implementation MUTreeNode

@dynamic icon, isLeaf, uniqueIdentifier;

+ (void) initialize
{
  _uniqueIdentifiers = [[NSMutableDictionary alloc] init];
}

- (id) initWithName: (NSString *) newName children: (NSArray *) newChildren
{
  if (!(self = [super init]))
    return nil;
  
  _name = [newName copy];
  _parent = nil;
  _uniqueIdentifier = [self _createUniqueIdentifier];
  
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
  return _uniqueIdentifier;
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
  [_children insertObject: object atIndex: index];
  [self _postWorldsDidChangeNotification];
}

- (void) insertChildren: (NSArray *) objects atIndexes: (NSIndexSet *) indexes
{
  for (MUTreeNode *child in objects)
    child.parent = self;
  
  [_children insertObjects: objects atIndexes: indexes];
  [self _postWorldsDidChangeNotification];
}

- (void) removeObjectFromChildrenAtIndex: (NSUInteger) index
{
  ((MUTreeNode *) _children[index]).parent = nil;
  [_children removeObjectAtIndex: index];
  [self _postWorldsDidChangeNotification];
}

- (void) removeChildrenAtIndexes: (NSIndexSet *) indexes
{
  NSArray *childrenAtIndexes = [_children objectsAtIndexes: indexes];
  
  for (MUTreeNode *child in childrenAtIndexes)
    child.parent = nil;
  
  [_children removeObjectsAtIndexes: indexes];
  [self _postWorldsDidChangeNotification];
}

- (void) replaceObjectInChildrenAtIndex: (NSUInteger) index withObject: (MUTreeNode *) object
{
  ((MUTreeNode *) _children[index]).parent = nil;
  object.parent = self;
  _children[index] = object;
  [self _postWorldsDidChangeNotification];
}

- (void) replaceChildrenAtIndexes: (NSIndexSet *) indexes withChildren: (NSArray *) objects
{
  [_children replaceObjectsAtIndexes: indexes withObjects: objects];
  [self _postWorldsDidChangeNotification];
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

#pragma mark - NSCoding protocol

- (void) encodeWithCoder: (NSCoder *) encoder
{
  [encoder encodeInt32: _currentTreeNodeVersion forKey: @"treeNodeVersion"];
  [encoder encodeObject: self.uniqueIdentifier forKey: @"uniqueIdentifier"];
  [encoder encodeObject: self.name forKey: @"name"];
  [encoder encodeObject: self.children forKey: @"children"];
}

- (id) initWithCoder: (NSCoder *) decoder
{
  if (!(self = [super init]))
    return nil;
  
  //uint32_t version = [coder decodeInt32ForKey: @"treeNodeVersion"];
  
  _uniqueIdentifier = [decoder decodeObjectForKey: @"uniqueIdentifier"];
  _uniqueIdentifiers[_uniqueIdentifier] = @YES;
  
  _name = [decoder decodeObjectForKey: @"name"];
  
  _children = [[decoder decodeObjectForKey: @"children"] mutableCopy];
  
  return self;
}

#pragma mark - NSCopying protocol

- (id) copyWithZone: (NSZone *) zone
{
  return [[[self class] alloc] initWithName: self.name children: self.children];
}

#pragma mark - Private methods

- (NSString *) _createUniqueIdentifier
{
  NSString *uuidString;
  do
  {
    CFUUIDRef uuid = CFUUIDCreate (kCFAllocatorDefault);
    
    uuidString = (__bridge_transfer NSString *) CFUUIDCreateString (kCFAllocatorDefault, uuid);
    
    CFRelease (uuid);
  }
  while (_uniqueIdentifiers[uuidString] != nil);
  
  _uniqueIdentifiers[uuidString] = @YES;
  return uuidString;
}

- (void) _postWorldsDidChangeNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUWorldsDidChangeNotification
                                                      object: self];
}

@end
