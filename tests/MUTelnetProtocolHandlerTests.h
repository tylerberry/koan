//
// MUTelnetProtocolHandlerTests.h
//
// Copyright (c) 2011 3James Software.
//

#import <J3Testing/J3TestCase.h>
#import "MUProtocolStack.h"
#import "MUTelnetProtocolHandler.h"

@class MUProtocolStack;

@interface MUTelnetProtocolHandlerTests : J3TestCase <MUProtocolStackDelegate, MUTelnetProtocolHandlerDelegate>
{
  MUProtocolStack *protocolStack;
  MUTelnetProtocolHandler *protocolHandler;
  NSMutableData *mockSocketData;
  NSMutableData *parsedData;
}

@end
