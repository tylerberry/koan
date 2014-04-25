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

+ (MUWorldRegistry *) defaultRegistry;

- (id) initWithWorldsFromUserDefaults;

- (MUWorld *) worldForUniqueIdentifier: (NSString *) identifier;

@end
