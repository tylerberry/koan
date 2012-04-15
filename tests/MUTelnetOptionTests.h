//
// MUTelnetOptionTests.h
//
// Copyright (c) 2012 3James Software.
//

#import "J3TestCase.h"
#import "MUTelnetOption.h"
#import "MUTelnetProtocolHandler.h"

@interface MUTelnetOptionTests : J3TestCase <MUTelnetOptionDelegate>
{
  MUTelnetOption *option;
  char flags;
}

@end
