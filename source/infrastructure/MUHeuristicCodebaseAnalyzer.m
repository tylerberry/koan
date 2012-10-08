//
// MUHeuristicCodebaseAnalyzer.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUHeuristicCodebaseAnalyzer.h"

@implementation MUHeuristicCodebaseAnalyzer

@synthesize codebase, codebaseFamily;

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  codebase = MUCodebaseUnknown;
  codebaseFamily = MUCodebaseFamilyUnknown;
  definitiveCodebaseFound = NO;
  
  return self;
}

#pragma mark - Accumulating heuristics

- (void) noteMSSPVariable: (NSString *) variable value: (NSString *) value
{
  if (definitiveCodebaseFound)
    return;
  
  // MSSP data is provided directly from the codebase. If it's lying, we're screwed anyway,
  // so any information acquired from MSSP is automatically treated as authoritative.
  
  if ([variable isEqualToString: @"CODEBASE"])
  {
    NSArray *valueWords = [value componentsSeparatedByString: @" "];
    
    if ([valueWords[0] isEqualToString: @"PennMUSH"])
    {
      definitiveCodebaseFound = YES;
      self.codebase = MUCodebasePennMUSH;
      self.codebaseFamily = MUCodebaseFamilyMUSH;
    }
  }
}

- (void) noteTelnetDo: (uint8_t) byte
{
  if (definitiveCodebaseFound)
    return;
}

- (void) noteTelnetDont: (uint8_t) byte
{
  if (definitiveCodebaseFound)
    return;
}

- (void) noteTelnetWill: (uint8_t) byte
{
  if (definitiveCodebaseFound)
    return;
}

- (void) noteTelnetWont: (uint8_t) byte
{
  if (definitiveCodebaseFound)
    return;
}

- (void) noteTextLine: (NSString *) text
{
  if (definitiveCodebaseFound)
    return;
}

#pragma mark - Codebase-specific behavior tweaks

- (BOOL) shouldSuppressGoAhead
{
  // PennMUSH chokes when it receives IAC GA.
  if (self.codebase == MUCodebasePennMUSH)
    return YES;
  
  return NO;
}

@end
