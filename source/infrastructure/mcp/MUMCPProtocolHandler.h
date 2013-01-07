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

+ (id) protocolHandlerWithConnectionState: (MUMUDConnectionState *) connectionState;
- (id) initWithConnectionState: (MUMUDConnectionState *) connectionState;

@end

#pragma mark -

@protocol MUMCPProtocolHandlerDelegate

- (void) log: (NSString *) message arguments: (va_list) args;

@end
