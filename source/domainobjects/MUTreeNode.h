//
// MUTreeNode.h
//
// Copyright (c) 2013 3James Software.
//

@interface MUTreeNode : NSObject <NSCoding, NSCopying>

@property (copy) NSString *name;
@property (readonly) NSImage *icon;
@property (copy) NSMutableArray *children;
@property (weak, nonatomic) MUTreeNode *parent;
@property (readonly) BOOL isLeaf;
@property (readonly) NSString *uniqueIdentifier;

- (instancetype) initWithName: (NSString *) name children: (NSArray *) children;

- (void) createNewUniqueIdentifier;
- (void) recursivelyUpdateParentsWithParentNode: (MUTreeNode *) topParentNode;

@end
