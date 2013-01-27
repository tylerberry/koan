//
// NSTreeController+IndexPaths.m
//
// Copyright (c) 2013 3James Software.
//

#import "NSTreeController+IndexPaths.h"

@implementation NSTreeController (IndexPaths)

- (NSIndexPath *) indexPathOfTreeNode: (NSTreeNode *) treeNode
{
  return [self indexPathOfRepresentedObject: treeNode.representedObject];
}

- (NSIndexPath *) indexPathOfRepresentedObject: (id) object
{
  return [self MU_indexPathOfRepresentedObject: object inNodes: [self.arrangedObjects childNodes]];
}

- (NSIndexPath *) MU_indexPathOfRepresentedObject: (id) object inNodes: (NSArray *) nodes
{
  for (NSTreeNode *node in nodes)
  {
    if ([node.representedObject isEqual: object])
      return node.indexPath;
    
    if (!node.isLeaf)
    {
      NSIndexPath *path = [self MU_indexPathOfRepresentedObject: object inNodes: node.childNodes];
      
      if (path)
        return path;
    }
  }
  return nil;
}

@end
