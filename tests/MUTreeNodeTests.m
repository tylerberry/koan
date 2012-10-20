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
  [_node addChild: child];
  
  [self assert: _node.children[0] equals: child];
}

- (void) testContainsChild
{
  MUTreeNode *child = [self testingNode];
  [_node addChild: child];
  
  [self assertTrue: [_node containsChild: child]];
}

- (void) testNoDuplicateChildren
{
  MUTreeNode *child = [self testingNode];
  [_node addChild: child];
  [_node addChild: child];
  
  [self assertUInteger: _node.children.count equals: 1];
}

- (void) testRemoveChild
{
  MUTreeNode *child = [self testingNode];
  [_node addChild: child];
  [_node removeChild: child];
  
  [self assertFalse: [_node containsChild: child]];
  [self assertNil: child.parent];
}

- (void) testReplaceChild
{
  MUTreeNode *child = [self testingNode];
  MUTreeNode *otherChild = [self testingNode];

  [_node addChild: child];
  
  [self assertTrue: [_node containsChild: child]];
  [self assert: child.parent equals: _node];
    
  [_node replaceChild: child withChild: otherChild];
    
  [self assertFalse: [_node containsChild: child]];
  [self assertNil: child.parent];
  [self assertTrue: [_node containsChild: otherChild]];
  [self assert: otherChild.parent equals: _node];
}

- (void) testNilChildren
{
  MUTreeNode *thisNode = [[MUTreeNode alloc] initWithName: @"" children: nil];
  MUTreeNode *child = [self testingNode];
  @try
  {
    [thisNode addChild: child];
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
