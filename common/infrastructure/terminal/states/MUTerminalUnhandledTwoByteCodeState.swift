//
//  MUTerminalUnhandledTwoByteState.swift
//  Koan
//
//  Created by Tyler Berry on 6/9/18.
//  Copyright © 2018 3James Software. All rights reserved.
//

import os.log

struct MUTerminalUnhandledTwoByteCodeState: MUTerminalState
{
  private let firstByte: UInt8
  
  init (firstByte: UInt8)
  {
    self.firstByte = firstByte
  }
  
  func parse (_ byte: UInt8,
              stateMachine: MUTerminalStateMachine,
              protocolHandler: MUTerminalProtocolHandlerProtocol) -> MUTerminalState
  {
    os_log ("Terminal: Unimplemented code: ESC %c %c (%02u/%02u %02u/%02u).",
      firstByte, byte, firstByte / 16, firstByte % 16, byte / 16, byte % 16)
    
    return MUTerminalTextState ()
  }
}
