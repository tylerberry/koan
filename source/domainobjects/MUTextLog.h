//
// MUTextLog.h
//
// Copyright (c) 2013 3James Software.
//

@interface MUTextLog : NSObject

@property (strong, nonatomic) NSString *content;
@property (strong, nonatomic) NSDictionary *headers;

- (id) initWithString: (NSString *) string;

- (void) fillDictionaryWithMetadata: (NSMutableDictionary *) dictionary;

@end
