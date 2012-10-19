//
//  MUSSLProtocolHandler.h
//  Koan
//
//  Created by Tyler Berry on 10/8/12.
//  Copyright (c) 2012 3James Software. All rights reserved.
//

#import "MUProtocolHandler.h"
#import "MUMUDConnectionState.h"

@interface MUSSLProtocolHandler : MUProtocolHandler
{
  MUMUDConnectionState *connectionState;
}

+ (id) protocolHandlerWithConnectionState: (MUMUDConnectionState *) newConnectionState;
- (id) initWithConnectionState: (MUMUDConnectionState *) newConnectionState;

@end
