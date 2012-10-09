//
//  MUSSLProtocolHandler.h
//  Koan
//
//  Created by Tyler Berry on 10/8/12.
//  Copyright (c) 2012 3James Software. All rights reserved.
//

#import "MUByteProtocolHandler.h"

@interface MUSSLProtocolHandler : MUByteProtocolHandler
{
  MUMUDConnectionState *connectionState;
}

+ (id) protocolHandlerWithStack: (MUProtocolStack *) stack
                connectionState: (MUMUDConnectionState *) telnetConnectionState;
- (id) initWithStack: (MUProtocolStack *) stack
     connectionState: (MUMUDConnectionState *) telnetConnectionState;

@end
