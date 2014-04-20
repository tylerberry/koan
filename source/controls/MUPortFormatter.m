//
// MUPortFormatter.m
//
// Copyright (c) 2013 3James Software.
//
// License:
// 
//   Permission is hereby granted, free of charge, to any person obtaining a
//   copy of this software and associated documentation files (the "Software"),
//   to deal in the Software without restriction, including without limitation
//   the rights to use, copy, modify, merge, publish, distribute, sublicense,
//   and/or sell copies of the Software, and to permit persons to whom the
//   Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in
//   all copies or substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//   DEALINGS IN THE SOFTWARE.
//

#import "MUPortFormatter.h"

@implementation MUPortFormatter

- (BOOL) getObjectValue: (id *) object forString: (NSString *) string errorDescription: (NSString **) error
{
  if (string == nil || [string compare: @""] == NSOrderedSame)
  {
    if (object)
      *object = @0;
    return YES;
  }
  
  NSScanner *scanner = [NSScanner scannerWithString: string];
  int intResult;
  
  if ([scanner scanInt: &intResult] && scanner.isAtEnd && intResult > 0 && intResult < 65536)
  {
    if (object)
      *object = @(intResult);
    return YES;
  }
  
  //if (error)
  //  *error = _(GBLErrorConverting);
  
  return NO;
}

- (BOOL) isPartialStringValid: (NSString *) partialString
             newEditingString: (NSString **) newString
             errorDescription: (NSString **) error
{
  if (partialString == nil || [partialString compare: @""] == NSOrderedSame)
    return YES;
  
  NSScanner *scanner = [NSScanner scannerWithString: partialString];
  int intResult;
  
  if (!([scanner scanInt: &intResult] && scanner.isAtEnd))
  {
    *newString = nil;
    return NO;
  }
  
  if (intResult > 65535)
  {
    *newString = @"65535";
    return NO;
  }
  
  if (intResult < 0)
  {
    *newString = nil;
    return NO;
  }
  
  return YES;
}

- (NSString *) stringForObjectValue: (id) object
{
  NSNumber *number = (NSNumber *) object;
  int value = number.intValue;
  
  if (value == 0 || number == nil)
    return nil;
  
  else return number.description;
}

@end
