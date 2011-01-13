//
//  MUTreeNodeTests.m
//  Koan
//
//  Created by Tyler Berry on 1/12/11.
//  Copyright 2011 3James Software. All rights reserved.
//

#import "MUTreeNodeTests.h"
#import "MUTreeNode.h"

@interface MUTreeNodeTests (Private)

- (MUTreeNode *) testingNode;

@end

#pragma mark -

@implementation MUTreeNodeTests

- (void) setUp
{
  node = [[MUTreeNode alloc] init];
}

- (void) tearDown
{
  [node release];
}


- (void) testAddChild
{
  MUTreeNode *child = [self testingNode];
  [node addChild: child];
  
  [self assert: [node.children objectAtIndex: 0] equals: child];
}

- (void) testContainsChild
{
  MUTreeNode *child = [self testingNode];
  [node addChild: child];
  
  [self assertTrue: [node containsChild: child]];
}

- (void) testNoDuplicateChildren
{
  MUTreeNode *child = [self testingNode];
  [node addChild: child];
  [node addChild: child];
  
  [self assertInt: [node.children count] equals: 1];
}

- (void) testRemoveChild
{
  MUTreeNode *child = [self testingNode];
  [node addChild: child];
  [node removeChild: child];
  
  [self assertFalse: [node containsChild: child]];
  [self assertNil: child.parent];
}

- (void) testReplaceChild
{
  MUTreeNode *child = [self testingNode];
  MUTreeNode *otherChild = [self testingNode];

  [node addChild: child];
  
  [self assertTrue: [node containsChild: child]];
  [self assert: child.parent equals: node];
    
  [node replaceChild: child withChild: otherChild];
    
  [self assertFalse: [node containsChild: child]];
  [self assertNil: child.parent];
  [self assertTrue: [node containsChild: otherChild]];
  [self assert: otherChild.parent equals: node];
}

- (void) testNilChildren
{
  MUTreeNode *thisNode = [[MUTreeNode alloc] initWithName: @"" children: nil];
  MUTreeNode *child = [self testingNode];
  @try
  {
    [thisNode addChild: child];
    [self assertInt: [thisNode.children count] equals: 1];
  }
  @finally
  {
    [thisNode release];
  }
}

@end

#pragma mark -

@implementation MUTreeNodeTests (Private)

- (MUTreeNode *) testingNode
{
  return [[[MUTreeNode alloc] init] autorelease];
}

@end
