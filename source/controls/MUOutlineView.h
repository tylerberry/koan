//
// MUOutlineView.h
//
// Copyright (c) 2013 3James Software.
//

@protocol MUOutlineViewDelegate <NSOutlineViewDelegate>

@optional
- (BOOL) outlineView: (NSOutlineView *) outlineView keyDown: (NSEvent *) event;

@end

#pragma mark -

@interface MUOutlineView : NSOutlineView

@property NSObject <MUOutlineViewDelegate> *delegate;

@end
