//
// MUTreeNode.h
//
// Copyright (c) 2013 3James Software.
//

@interface MUTreeNode : NSObject <NSCopying, NSSecureCoding>

@property (copy) NSString *name;
@property (readonly) NSImage *icon;
@property (copy) NSMutableArray *children;
@property (weak, nonatomic) MUTreeNode *parent;
@property (readonly) BOOL isLeaf;
@property (readonly) NSString *uniqueIdentifier;

- (instancetype) initWithCoder: (NSCoder *) decoder NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithName: (NSString *) name children: (NSArray *) children NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithName: (NSString *) name;

- (void) createNewUniqueIdentifier;
- (void) recursivelyUpdateParentsWithParentNode: (MUTreeNode *) topParentNode;

@end
