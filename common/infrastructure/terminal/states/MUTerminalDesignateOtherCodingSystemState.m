//
// MUTerminalDesignateOtherCodingSystemState.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalDesignateOtherCodingSystemState.h"

#import "MUTerminalTextState.h"

@implementation MUTerminalDesignateOtherCodingSystemState

- (MUTerminalState *) parse: (uint8_t) byte
            forStateMachine: (MUTerminalStateMachine *) stateMachine
            protocolHandler: (NSObject <MUTerminalProtocolHandler> *) protocolHandler
{
  switch (byte)
  {
    case 0x40: // '@' designates ISO-8859-1.
      
      // FIXME: This is not actually the meaning of ESC % @, which should mean "Return to ECMA-35 coding system."
      
      [protocolHandler setStringEncoding: NSISOLatin1StringEncoding];
      [protocolHandler log: @"Terminal: Changed to ISO-8859-1."];
      break;

    case 0x47: // 'G' designates UTF-8.
      
      // FIXME: This is actually a little more complicated. In addition to setting the encoding to UTF-8, this should
      // disable ECMA-35 handling until a ESC % @ is received. See ECMA-35 and supporting documentation, this is pretty
      // complicated really.
      
      [protocolHandler setStringEncoding: NSUTF8StringEncoding];
      [protocolHandler log: @"Terminal: Changed to UTF-8."];
      break;

    default:
      [protocolHandler log: @"Terminal: Unrecognized character set requested: ESC %% %c (02/05 %02u/%02u)",
         byte, byte / 16, byte % 16];
  }

  return [MUTerminalTextState state];
}

@end
