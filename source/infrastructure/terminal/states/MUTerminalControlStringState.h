//
//  MUTerminalControlStringState.h
//  Koan
//
//  Created by Tyler Berry on 4/25/14.
//  Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalState.h"

enum MUTerminalControlStringTypes
{
  MUTerminalControlStringTypeOperatingSystemCommand = 0,
  MUTerminalControlStringTypePrivacyMessage = 1,
  MUTerminalControlStringTypeApplicationProgram = 2
};

@interface MUTerminalControlStringState : MUTerminalState

+ (id) stateWithControlStringType: (enum MUTerminalControlStringTypes) controlStringType;

- (id) initWithControlStringType: (enum MUTerminalControlStringTypes) controlStringType;

@end
