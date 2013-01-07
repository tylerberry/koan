//
// MUWorldRegistry.h
//
// Copyright (c) 2013 3James Software.
//

@class MUWorld;

@interface MUWorldRegistry : NSObject

@property (copy) NSMutableArray *worlds;

+ (MUWorldRegistry *) defaultRegistry;

- (id) initWithWorldsFromUserDefaults;

- (MUWorld *) worldForUniqueIdentifier: (NSString *) identifier;

@end
