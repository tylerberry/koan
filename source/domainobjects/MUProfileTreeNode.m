//
// MUProfileTreeNode.m
//
// Copyright (c) 2010 3James Software.
//

#import "MUProfileTreeNode.h"

@implementation MUProfileTreeNode

@synthesize nodeTitle, children, isLeaf, nodeIcon;

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  nodeTitle = [[NSString alloc] initWithString: @"Base Node"];
  children = [[NSMutableArray alloc] init];
  isLeaf = NO;
  
  return self;
}

- (id) initAsLeaf
{
  if (!(self = [self init]))
    return nil;
  
  isLeaf = YES;
  
  return self;
}

- (void) dealloc
{
  [nodeTitle release];
  [children release];
  [nodeIcon release];
  [super dealloc];
}

- (BOOL) isDraggable
{
  return NO;
}

#pragma mark -
#pragma mark NSCopying protocol

- (id) initWithCoder: (NSCoder *) coder
{
  if (!(self = [super init]))
    return nil;
  
  nodeTitle = [coder decodeObjectForKey: @"nodeTitle"];
  children = [coder decodeObjectForKey: @"children"];
  isLeaf = [coder decodeBoolForKey: @"isLeaf"];
  nodeIcon = [coder decodeObjectForKey: @"nodeIcon"];
	
	return self;
}

- (void) encodeWithCoder: (NSCoder *) coder
{
  [coder encodeObject: self.nodeTitle forKey: @"nodeTitle"];
  [coder encodeObject: self.children forKey: @"children"];
  [coder encodeBool: self.isLeaf forKey: @"isLeaf"];
  [coder encodeObject: self.nodeIcon forKey: @"nodeIcon"];
}

#pragma mark -
#pragma mark NSCopying protocol

- (id) copyWithZone: (NSZone *) zone
{
	MUProfileTreeBaseNode *newNode = [[MUProfileTreeBaseNode allocWithZone: zone] init];
  
  newNode.nodeTitle = self.nodeTitle;
  newNode.children = self.children;
  newNode.isLeaf = self.isLeaf;
  newNode.nodeIcon = self.nodeIcon;
	
	return newNode;
}

@end
