//
// MUTextLogger.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUFilter.h"

@class MUPlayer;
@class MUWorld;

@interface MUTextLogger : MUFilter

+ (instancetype) filter NS_UNAVAILABLE;
+ (instancetype) filterWithWorld: (MUWorld *) world;
+ (instancetype) filterWithWorld: (MUWorld *) world player: (MUPlayer *) player;

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithOutputStream: (NSOutputStream *) outputStream NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithWorld: (MUWorld *) world;
- (instancetype) initWithWorld: (MUWorld *) world player: (MUPlayer *) player;

@end
