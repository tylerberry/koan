//
//  MUTreeNodeTests.m
//  Koan
//
//  Created by Tyler Berry on 1/12/11.
//  Copyright 2011 3James Software. All rights reserved.
//

#import "MUTreeNodeTests.h"
#import "MUTreeNode.h"

@interface MUTreeNodeTests ()
{
  MUTreeNode *_node;
}

- (MUTreeNode *) testingNode;

@end

#pragma mark -

@implementation MUTreeNodeTests

- (void) setUp
{
  _node = [[MUTreeNode alloc] init];
}

- (void) tearDown
{
  _node = nil;
}

- (void) testAddChild
{
  MUTreeNode *child = [self testingNode];
  [_node insertValue: child inPropertyWithKey: @"children"];
  
  [self assert: _node.children[0] equals: child];
}

- (void) testContainsChild
{
  MUTreeNode *child = [self testingNode];
  [_node insertValue: child inPropertyWithKey: @"children"];
  
  [self assertTrue: [_node.children containsObject: child]];
}

- (void) testNoDuplicateChildren
{
  MUTreeNode *child = [self testingNode];
  [_node insertValue: child inPropertyWithKey: @"children"];
  [_node insertValue: child inPropertyWithKey: @"children"];
  
  [self assertUInteger: _node.children.count equals: 1];
}

- (void) testRemoveChild
{
  MUTreeNode *child = [self testingNode];
  [_node insertValue: child inPropertyWithKey: @"children"];
  [_node removeValueAtIndex: [_node.children indexOfObject: child] fromPropertyWithKey: @"children"];
  
  [self assertFalse: [_node.children containsObject: child]];
  [self assertNil: child.parent];
}

- (void) testReplaceChild
{
  MUTreeNode *child = [self testingNode];
  MUTreeNode *otherChild = [self testingNode];
  
  [_node insertValue: child inPropertyWithKey: @"children"];
  
  [self assertTrue: [_node.children containsObject: child]];
  [self assert: child.parent equals: _node];
  
  [_node replaceValueAtIndex: [_node.children indexOfObject: child]
           inPropertyWithKey: @"children"
                   withValue: otherChild];
    
  [self assertFalse: [_node.children containsObject: child]];
  [self assertNil: child.parent];
  [self assertTrue: [_node.children containsObject: otherChild]];
  [self assert: otherChild.parent equals: _node];
}

- (void) testNilChildren
{
  MUTreeNode *thisNode = [[MUTreeNode alloc] initWithName: @"" children: nil];
  MUTreeNode *child = [self testingNode];
  @try
  {
    [thisNode insertValue: child inPropertyWithKey: @"children"];
    [self assertUInteger: thisNode.children.count equals: 1];
  }
  @finally
  {
    thisNode = nil;
  }
}

#pragma mark - Private methods

- (MUTreeNode *) testingNode
{
  return [[MUTreeNode alloc] init];
}

@end
