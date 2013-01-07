//
// MUHistoryRing.h
//
// Copyright (c) 2013 3James Software.
//

@interface MUHistoryRing : NSObject

@property (readonly) NSUInteger count;

+ (MUHistoryRing *) historyRing;

- (NSString *) stringAtIndex: (NSUInteger) ringIndex;

// These methods are all O(1).

- (void) saveString: (NSString *) string;
- (void) updateString: (NSString *) string;
- (NSString *) currentString;
- (NSString *) nextString;
- (NSString *) previousString;

- (void) resetSearchCursor;

// These methods are all O(n).

- (NSUInteger) numberOfUniqueMatchesForStringPrefix: (NSString *) prefix;
- (NSString *) searchForwardForStringPrefix: (NSString *) prefix;
- (NSString *) searchBackwardForStringPrefix: (NSString *) prefix;

@end
