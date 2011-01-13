//
// MUTreeNode.h
//
// Copyright (c) 2010 3James Software.
//

#import <Cocoa/Cocoa.h>

@interface MUTreeNode : NSObject
{
  NSString *name;
  NSMutableArray *children;
  MUTreeNode *parent;
}

@property (copy) NSString *name;
@property (copy) NSMutableArray *children;
@property (assign) MUTreeNode *parent;
@property (readonly) BOOL isLeaf;

- (id) initWithName: (NSString *) newName children: (NSArray *) newChildren;
- (id) init;

- (void) recursivelyUpdateParentsWithParentNode: (MUTreeNode *) topParentNode;

// Array-like functions.
- (void) addChild: (MUTreeNode *) child;
- (BOOL) containsChild: (MUTreeNode *) child;
- (NSUInteger) indexOfChild: (MUTreeNode *) child;
- (void) insertObject: (MUTreeNode *) child inChildrenAtIndex: (NSUInteger) childIndex;
- (void) removeObjectFromChildrenAtIndex: (NSUInteger) childIndex;
- (void) removeChild: (MUTreeNode *) child;
- (void) replaceChild: (MUTreeNode *) oldChild withChild: (MUTreeNode *) newChild;

@end
