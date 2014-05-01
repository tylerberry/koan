//
// MUTelnetOptionTests.h
//
// Copyright (c) 2013 3James Software.
//



#import "MUTelnetOption.h"
#import "MUTelnetProtocolHandler.h"

@interface MUTelnetOptionTests : XCTestCase
 <MUTelnetOptionDelegate>
{
  MUTelnetOption *option;
  char flags;
}

@end
