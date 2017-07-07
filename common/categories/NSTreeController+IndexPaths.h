//
// NSTreeController+IndexPaths.h
//
// Copyright (c) 2013 3James Software.
//

#import <Cocoa/Cocoa.h>

@interface NSTreeController (IndexPaths)

- (NSIndexPath *) indexPathOfTreeNode: (NSTreeNode *) object;
- (NSIndexPath *) indexPathOfRepresentedObject: (id) object;

@end
