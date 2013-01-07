//
// MUTextLogDocument.h
//
// Copyright (c) 2013 3James Software.
//

@interface MUTextLogDocument : NSDocument

@property (strong, nonatomic) NSString *content;
@property (strong, nonatomic) NSDictionary *headers;

- (id) mockInitWithString: (NSString *) string;

- (void) fillDictionaryWithMetadata: (NSMutableDictionary *) dictionary;
- (NSString *) headerForKey: (id) key;

@end
