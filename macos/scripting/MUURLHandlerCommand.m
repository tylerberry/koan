//
// MUURLHandlerCommand.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUURLHandlerCommand.h"

#import "MUApplicationController.h"

@implementation MUURLHandlerCommand

- (id) performDefaultImplementation
{
  if ([[NSApp delegate] isKindOfClass: [MUApplicationController class]])
  {
    [(MUApplicationController *) [NSApp delegate] connectToURL: [NSURL URLWithString: self.directParameter]];
  }
  
  return nil;
}

@end
