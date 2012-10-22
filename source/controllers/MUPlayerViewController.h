//
// MUPlayerViewController.h
//
// Copyright (c) 2012 3James Software.
//

@class MUPlayer;

@interface MUPlayerViewController : NSViewController
{
  IBOutlet NSButton *clearTextButton;
}

@property (strong) MUPlayer *player;

@end
