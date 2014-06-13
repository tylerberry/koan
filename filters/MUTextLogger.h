//
// MUTextLogger.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUFilter.h"

@class MUPlayer;
@class MUWorld;

@interface MUTextLogger : MUFilter

+ (instancetype) filterWithWorld: (MUWorld *) world;
+ (instancetype) filterWithWorld: (MUWorld *) world player: (MUPlayer *) player;

// Designated initializer.
- (instancetype) initWithOutputStream: (NSOutputStream *) outputStream;
- (instancetype) initWithWorld: (MUWorld *) world;
- (instancetype) initWithWorld: (MUWorld *) world player: (MUPlayer *) player;

@end
