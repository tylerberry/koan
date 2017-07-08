//
// MUMCPProtocolHandler.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUProtocolHandler.h"
#import "MUMUDConnectionState.h"

@protocol MUMCPProtocolHandlerDelegate;

@interface MUMCPProtocolHandler : MUProtocolHandler

@property (weak, nonatomic) NSObject <MUMCPProtocolHandlerDelegate> *delegate;

+ (instancetype) protocolHandlerWithConnectionState: (MUMUDConnectionState *) connectionState;

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithConnectionState: (MUMUDConnectionState *) connectionState NS_DESIGNATED_INITIALIZER;

@end

#pragma mark -

@protocol MUMCPProtocolHandlerDelegate

- (void) log: (NSString *) message arguments: (va_list) args;

@end
