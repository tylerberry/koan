//
// MUCodingService.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

@class MUPlayer;
@class MUProxySettings;

@interface MUCodingService : NSObject

+ (void) decodePlayer: (MUPlayer *) player withCoder: (NSCoder *) decoder;
+ (void) decodeProxySettings: (MUProxySettings *) settings withCoder: (NSCoder *) decoder;

+ (void) encodePlayer: (MUPlayer *) player withCoder: (NSCoder *) encoder;
+ (void) encodeProxySettings: (MUProxySettings *) settings withCoder: (NSCoder *) decoder;

@end
