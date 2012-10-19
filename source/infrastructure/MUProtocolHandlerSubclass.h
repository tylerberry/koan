//
// MUProtocolHandlerSubclass.h
//
// Copyright (c) 2012 3James Software.
//

#import "MUProtocolHandler.h"

#define PASS_ON_PARSED_BYTE(byte) [self.previousHandler parseByte:(byte)]
#define PASS_ON_PREPROCESSED_BYTE(byte) [self.nextHandler preprocessByte:(byte)]
#define PASS_ON_PREPROCESSED_FOOTER_DATA(data) [self.nextHandler preprocessFooterData:(data)]
