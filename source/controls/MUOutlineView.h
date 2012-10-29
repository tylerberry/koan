//
//  MUOutlineView.h
//  Koan
//
//  Created by Tyler Berry on 10/27/12.
//  Copyright (c) 2012 3James Software. All rights reserved.
//

@protocol MUOutlineViewDelegate <NSOutlineViewDelegate>

@optional
- (BOOL) outlineView: (NSOutlineView *) outlineView keyDown: (NSEvent *) event;

@end

#pragma mark -

@interface MUOutlineView : NSOutlineView

@property NSObject <MUOutlineViewDelegate> *delegate;

@end
