//
// MUTextLog.h
//
// Copyright (c) 2013 3James Software.
//

@interface MUTextLog : NSObject

@property (strong, nonatomic) NSString *content;
@property (strong, nonatomic) NSDictionary *headers;

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithString: (NSString *) string NS_DESIGNATED_INITIALIZER;

- (void) fillDictionaryWithMetadata: (NSMutableDictionary *) dictionary;

@end
