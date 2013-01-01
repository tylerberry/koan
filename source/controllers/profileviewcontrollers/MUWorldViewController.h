//
// MUWorldViewController.h
//
// Copyright (c) 2013 3James Software.
//

@class MUWorld;

@interface MUWorldViewController : NSViewController

@property (strong) MUWorld *world;

@property (weak) IBOutlet NSView *firstView;
@property (weak) IBOutlet NSView *lastView;

@end
