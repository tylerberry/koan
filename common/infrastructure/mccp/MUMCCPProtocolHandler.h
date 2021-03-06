//
// MUMCCPProtocolHandler.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUProtocolHandler.h"
#import "MUMUDConnectionState.h"

@protocol MUMCCPProtocolHandlerDelegate

- (void) log: (NSString *) message arguments: (va_list) args;

@end

#pragma mark -

@interface MUMCCPProtocolHandler : MUProtocolHandler

@property (weak) NSObject <MUMCCPProtocolHandlerDelegate> *delegate;

+ (instancetype) protocolHandlerWithConnectionState: (MUMUDConnectionState *) connectionState;

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithConnectionState: (MUMUDConnectionState *) connectionState NS_DESIGNATED_INITIALIZER;

@end
