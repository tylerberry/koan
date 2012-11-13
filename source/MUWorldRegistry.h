//
// MUWorldRegistry.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

@class MUWorld;

@interface MUWorldRegistry : NSObject

@property (copy) NSMutableArray *worlds;

+ (MUWorldRegistry *) defaultRegistry;

- (id) initWithWorldsFromUserDefaults;

- (MUWorld *) worldForUniqueIdentifier: (NSString *) identifier;

@end
