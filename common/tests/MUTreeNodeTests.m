//
// MUTreeNodeTests.m
//
// Copyright 2011 3James Software. All rights reserved.
//

#import "MUTreeNode.h"

@interface MUTreeNodeTests : XCTestCase

- (MUTreeNode *) _testingNode;

@end

#pragma mark -

@implementation MUTreeNodeTests
{
  MUTreeNode *_node;
}

- (void) setUp
{
  [super setUp];
  _node = [[MUTreeNode alloc] init];
}

- (void) tearDown
{
  _node = nil;
  [super tearDown];
}

- (void) testAddChild
{
  MUTreeNode *child = [self _testingNode];
  [_node insertValue: child inPropertyWithKey: @"children"];
  
  XCTAssertEqualObjects (_node.children[0], child);
}

- (void) testContainsChild
{
  MUTreeNode *child = [self _testingNode];
  [_node insertValue: child inPropertyWithKey: @"children"];
  
  XCTAssertTrue ([_node.children containsObject: child]);
}

- (void) testCopyHasDifferentUniqueIdentifier
{
  MUTreeNode *child = [self _testingNode];
  MUTreeNode *copy = [child copy];
  
  XCTAssertNotEqualObjects (child.uniqueIdentifier, copy.uniqueIdentifier);
}

- (void) testRemoveChild
{
  MUTreeNode *child = [self _testingNode];
  [_node insertValue: child inPropertyWithKey: @"children"];
  [_node removeValueAtIndex: [_node.children indexOfObject: child] fromPropertyWithKey: @"children"];
  
  XCTAssertFalse ([_node.children containsObject: child]);
  XCTAssertNil (child.parent);
}

- (void) testReplaceChild
{
  MUTreeNode *child = [self _testingNode];
  MUTreeNode *otherChild = [self _testingNode];
  
  [_node insertValue: child inPropertyWithKey: @"children"];
  
  XCTAssertTrue ([_node.children containsObject: child]);
  XCTAssertEqualObjects (child.parent, _node);
  
  [_node replaceValueAtIndex: [_node.children indexOfObject: child]
           inPropertyWithKey: @"children"
                   withValue: otherChild];
    
  XCTAssertFalse ([_node.children containsObject: child]);
  XCTAssertNil (child.parent);
  XCTAssertTrue ([_node.children containsObject: otherChild]);
  XCTAssertEqualObjects (otherChild.parent, _node);
}

- (void) testNilChildren
{
  MUTreeNode *thisNode = [[MUTreeNode alloc] initWithName: @"" children: nil];
  MUTreeNode *child = [self _testingNode];
  @try
  {
    [thisNode insertValue: child inPropertyWithKey: @"children"];
    XCTAssertEqual (thisNode.children.count, (NSUInteger) 1);
  }
  @finally
  {
    thisNode = nil;
  }
}

#pragma mark - Private methods

- (MUTreeNode *) _testingNode
{
  return [[MUTreeNode alloc] init];
}

@end
