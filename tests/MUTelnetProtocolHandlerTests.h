//
// MUTelnetProtocolHandlerTests.h
//
// Copyright (c) 2013 3James Software.
//

#import "J3TestCase.h"
#import "MUProtocolStack.h"
#import "MUTelnetProtocolHandler.h"

@class MUProtocolStack;

@interface MUTelnetProtocolHandlerTests : J3TestCase <MUProtocolStackDelegate, MUTelnetProtocolHandlerDelegate>

@end
