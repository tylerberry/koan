//
// MUTextLogger.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUFilter.h"

@class MUPlayer;
@class MUWorld;

@interface MUTextLogger : MUFilter

+ (MUFilter *) filterWithWorld: (MUWorld *) world;
+ (MUFilter *) filterWithWorld: (MUWorld *) world player: (MUPlayer *) player;

// Designated initializer.
- (id) initWithOutputStream: (NSOutputStream *) outputStream;
- (id) initWithWorld: (MUWorld *) world;
- (id) initWithWorld: (MUWorld *) world player: (MUPlayer *) player;

@end
