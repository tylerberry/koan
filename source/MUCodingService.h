//
// MUCodingService.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

@class MUPlayer;
@class MUProfile;
@class MUProxySettings;
@class MUWorld;

@interface MUCodingService : NSObject

+ (void) decodePlayer: (MUPlayer *) player withCoder: (NSCoder *) decoder;
+ (void) decodeProfile: (MUProfile *) profile withCoder: (NSCoder *) decoder;
+ (void) decodeProxySettings: (MUProxySettings *) settings withCoder: (NSCoder *) decoder;

+ (void) encodePlayer: (MUPlayer *) player withCoder: (NSCoder *) encoder;
+ (void) encodeProfile: (MUProfile *) profile withCoder: (NSCoder *) encoder;
+ (void) encodeProxySettings: (MUProxySettings *) settings withCoder: (NSCoder *) decoder;

@end
