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

- (instancetype) initWithName: (NSString *) name children: (NSArray *) children
{
  if (!(self = [super init]))
    return nil;
  
  _name = [name copy];
  _parent = nil;
  _uniqueIdentifier = [self _createUniqueIdentifier];
  _uniqueIdentifiers[_uniqueIdentifier] = @YES;
  
  if (children)
    _children = [children mutableCopy];
  else
    _children = [[NSMutableArray alloc] init];

  return self;
}

- (instancetype) initWithName: (NSString *) name
{
  return [self initWithName: name children: nil];
}

- (instancetype) init
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

- (void) insertInChildren: (MUTreeNode *) object
{
  [self insertObject: object inChildrenAtIndex: _children.count];
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

- (void) createNewUniqueIdentifier
{
  _uniqueIdentifier = [self _createUniqueIdentifier];
  _uniqueIdentifiers[_uniqueIdentifier] = @YES;
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

#pragma mark - NSCopying protocol

- (id) copyWithZone: (NSZone *) zone
{
  return [[[self class] alloc] initWithName: self.name children: self.children];
}

#pragma mark - NSSecureCoding protocol

+ (BOOL) supportsSecureCoding
{
  return YES;
}

- (void) encodeWithCoder: (NSCoder *) encoder
{
  [encoder encodeInt32: _currentTreeNodeVersion forKey: @"treeNodeVersion"];
  [encoder encodeObject: self.uniqueIdentifier forKey: @"uniqueIdentifier"];
  [encoder encodeObject: self.name forKey: @"name"];
  [encoder encodeObject: self.children forKey: @"children"];
}

- (instancetype) initWithCoder: (NSCoder *) decoder
{
  if (!(self = [super init]))
    return nil;
  
  //uint32_t version = [coder decodeInt32ForKey: @"treeNodeVersion"];
  
  _uniqueIdentifier = [decoder decodeObjectOfClass: [NSString class] forKey: @"uniqueIdentifier"];
  _uniqueIdentifiers[_uniqueIdentifier] = @YES;
  
  _name = [decoder decodeObjectOfClass: [NSString class] forKey: @"name"];
  
  _children = [[decoder decodeObjectOfClass: [NSArray class] forKey: @"children"] mutableCopy];
  
  return self;
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
