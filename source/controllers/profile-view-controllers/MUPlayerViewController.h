//
// MUPlayerViewController.h
//
// Copyright (c) 2013 3James Software.
//

@class MUPlayer;

@interface MUPlayerViewController : NSViewController
{
  IBOutlet NSButton *clearTextButton;
}

@property (strong) MUPlayer *player;

@property (weak) IBOutlet NSView *firstView;
@property (weak) IBOutlet NSView *lastView;

@end
