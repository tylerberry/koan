//
// MUTreeNode.h
//
// Copyright (c) 2013 3James Software.
//

#import <Cocoa/Cocoa.h>

@interface MUTreeNode : NSObject <NSCoding, NSCopying>

@property (copy) NSString *name;
@property (readonly) NSImage *icon;
@property (copy) NSMutableArray *children;
@property (weak, nonatomic) MUTreeNode *parent;
@property (readonly) BOOL isLeaf;
@property (readonly) NSString *uniqueIdentifier;

- (id) initWithName: (NSString *) newName children: (NSArray *) newChildren;
- (id) init;

- (void) recursivelyUpdateParentsWithParentNode: (MUTreeNode *) topParentNode;

@end
