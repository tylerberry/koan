//
// MUTelnetProtocolHandlerTests.h
//
// Copyright (c) 2013 3James Software.
//



#import "MUProtocolStack.h"
#import "MUTelnetProtocolHandler.h"

@class MUProtocolStack;

@interface MUTelnetProtocolHandlerTests : XCTestCase
 <MUProtocolStackDelegate, MUTelnetProtocolHandlerDelegate>

@end
