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
    
    if ([valueWords[0] isEqualToString: @"StickyMUSH"])
    {
      _definitiveCodebaseFound = YES;
      self.codebase = MUCodebaseStickyMUSH;
      self.codebaseFamily = MUCodebaseFamilyPennMUSH;
    }
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

- (void) noteTextLine: (NSString *) textLine
{
  // TODO: Make this use regex instead, it's probably faster. Note we can't use NSRegularExpression because we run on
  // 10.6.
  
  if (_definitiveCodebaseFound)
    return;
  
  if (self.codebaseFamily == MUCodebaseFamilyUnknown)
  {
    // It's easy for people to talk about other codebases in chat, and we don't want to reset the heuristic every time
    // somebody does because that would be awful. Therefore if we have any guess at all as to what we're running on, we
    // shouldn't do textual matching anymore. We're hoping this is sent early, in the connect banner for example.
    
    if ([textLine.lowercaseString rangeOfString: @"pennmush"].location != NSNotFound)
    {
      self.codebase = MUCodebasePennMUSH;
      self.codebaseFamily = MUCodebaseFamilyPennMUSH;
    }
    else if ([textLine.lowercaseString rangeOfString: @"mux"].location != NSNotFound)
    {
      self.codebase = MUCodebaseTinyMUX;
      self.codebaseFamily = MUCodebaseFamilyTinyMUSH;
    }
    else if ([textLine.lowercaseString rangeOfString: @"dgd"].location != NSNotFound)
    {
      self.codebase = MUCodebaseLPMUDWithDGD;
      self.codebaseFamily = MUCodebaseFamilyMUD;
    }
    else if ([textLine.lowercaseString rangeOfString: @"lpmud"].location != NSNotFound)
    {
      self.codebase = MUCodebaseLPMUD;
      self.codebaseFamily = MUCodebaseFamilyMUD;
    }
    else if ([textLine.lowercaseString rangeOfString: @"mud"].location != NSNotFound)
    {
      self.codebaseFamily = MUCodebaseFamilyMUD;
    }
    else if ([textLine.lowercaseString rangeOfString: @"mush"].location != NSNotFound)
    {
      self.codebaseFamily = MUCodebaseFamilyTinyMUSH;
    }
  }
}

#pragma mark - Codebase-specific behavior tweaks

- (BOOL) shouldSuppressGoAhead
{
  // PennMUSH chokes when it receives IAC GA.
  if (self.codebaseFamily == MUCodebaseFamilyPennMUSH)
    return YES;
  
  return NO;
}

@end
