//
// MUCodingService.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

@class MUProxySettings;

@interface MUCodingService : NSObject

+ (void) decodeProxySettings: (MUProxySettings *) settings withCoder: (NSCoder *) decoder;

+ (void) encodeProxySettings: (MUProxySettings *) settings withCoder: (NSCoder *) decoder;

@end
