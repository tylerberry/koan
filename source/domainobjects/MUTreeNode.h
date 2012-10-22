//
// MUTreeNode.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

@interface MUTreeNode : NSObject

@property (copy) NSString *name;
@property (readonly) NSImage *icon;
@property (copy) NSMutableArray *children;
//@property (readonly) NSUInteger count;
@property (weak, nonatomic) MUTreeNode *parent;
@property (readonly) BOOL isLeaf;
@property (readonly) NSString *uniqueIdentifier;

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
