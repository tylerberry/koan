//
// MUHeuristicCodebaseAnalyzer.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUHeuristicCodebaseAnalyzer.h"

@interface MUHeuristicCodebaseAnalyzer ()
{
  BOOL _definitiveCodebaseFound;
}

@end

#pragma mark -

@implementation MUHeuristicCodebaseAnalyzer

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  _codebase = MUCodebaseUnknown;
  _codebaseFamily = MUCodebaseFamilyUnknown;
  _definitiveCodebaseFound = NO;
  
  return self;
}

#pragma mark - Accumulating heuristics

- (void) noteMSSPVariable: (NSString *) variable value: (NSString *) value
{
  if (_definitiveCodebaseFound)
    return;
  
  // MSSP data is provided directly from the codebase. If it's lying, we're screwed anyway,
  // so any information acquired from MSSP is automatically treated as authoritative.
  
  if ([variable isEqualToString: @"CODEBASE"])
  {
    NSArray *valueWords = [value componentsSeparatedByString: @" "];
    
    if ([valueWords[0] isEqualToString: @"PennMUSH"])
    {
      _definitiveCodebaseFound = YES;
      self.codebase = MUCodebasePennMUSH;
      self.codebaseFamily = MUCodebaseFamilyPennMUSH;
    }
  }
}

- (void) noteTelnetDo: (uint8_t) byte
{
  if (_definitiveCodebaseFound)
    return;
}

- (void) noteTelnetDont: (uint8_t) byte
{
  if (_definitiveCodebaseFound)
    return;
}

- (void) noteTelnetWill: (uint8_t) byte
{
  if (_definitiveCodebaseFound)
    return;
}

- (void) noteTelnetWont: (uint8_t) byte
{
  if (_definitiveCodebaseFound)
    return;
}

- (void) noteTextLine: (NSString *) text
{
  if (_definitiveCodebaseFound)
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
