//
// MUWorldRegistry.h
//
// Copyright (c) 2013 3James Software.
//

@class MUWorld;

@interface MUWorldRegistry : NSObject

@property (copy) NSMutableArray *worlds; // Needs to be readwrite for integration with MUProfilesSection.
                                         //
                                         // Could possibly be rewritten to have better encapsulation? But don't just
                                         // change this without dealing with that as well.

+ (instancetype) defaultRegistry;

- (instancetype) initWithWorlds: (NSArray *) worlds NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithWorldsFromUserDefaults;

- (MUWorld *) worldForUniqueIdentifier: (NSString *) identifier;

@end
