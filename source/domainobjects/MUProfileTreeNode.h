//
// MUProfileTreeNode.h
//
// Copyright (c) 2010 3James Software.
//

#import <Cocoa/Cocoa.h>

@interface MUProfileTreeNode : NSObject <NSCoding, NSCopying>
{
  NSString *nodeTitle;
  NSMutableArray *children;
  BOOL isLeaf;
  NSImage *nodeIcon;
}

@property (copy) NSString *nodeTitle;
@property (copy) NSMutableArray *children;
@property (assign, nonatomic) BOOL isLeaf;
@property (retain) NSImage *nodeIcon;

- (id) initAsLeaf;

- (BOOL) isDraggable;

@end
