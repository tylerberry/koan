//
// MUHeuristicCodebaseAnalyzer.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUHeuristicCodebaseAnalyzer.h"

@interface MUHeuristicCodebaseAnalyzer ()

- (void) _log: (NSString *) message, ...;

@end

#pragma mark -

@implementation MUHeuristicCodebaseAnalyzer
{
  BOOL _definitiveCodebaseFound;
}

- (instancetype) initWithDelegate: (NSObject <MUHeuristicCodebaseAnalyzerDelegate> *) newDelegate
{
  if (!(self = [super init]))
    return nil;
  
  _delegate = newDelegate;
  
  _codebase = MUCodebaseUnknown;
  _codebaseFamily = MUCodebaseFamilyUnknown;
  _definitiveCodebaseFound = NO;
  
  return self;
}

- (instancetype) init
{
  return [self initWithDelegate: nil];
}

#pragma mark - Accumulating heuristics

- (void) noteMSSPVariable: (NSString *) variableString value: (NSString *) valueString
{
  if (_definitiveCodebaseFound)
    return;
  
  // MSSP data is provided directly from the codebase. If it's lying, we're screwed anyway, so any information acquired
  // from MSSP is automatically treated as authoritative.

  if ([variableString isEqualToString: @"NAME"])
  {
    if ([valueString rangeOfString: @"SlothMUD"].location != NSNotFound)
    {
      _definitiveCodebaseFound = YES;
      _codebase = MUCodebaseSlothMUD;
      _codebaseFamily = MUCodebaseFamilyDikuMUD;

      [self _log: @"Analyzer: MSSP identifies as SlothMUD."];
    }
  }
  else if ([variableString isEqualToString: @"CODEBASE"])
  {
    if ([valueString rangeOfString: @"StickyMUSH"].location != NSNotFound)
    {
      _definitiveCodebaseFound = YES;
      _codebase = MUCodebaseStickyMUSH;
      _codebaseFamily = MUCodebaseFamilyPennMUSH;
      
      [self _log: @"Analyzer: MSSP identifies as StickyMUSH."];
    }
    else if ([valueString rangeOfString: @"PennMUSH"].location != NSNotFound)
    {
      _definitiveCodebaseFound = YES;
      _codebase = MUCodebasePennMUSH;
      _codebaseFamily = MUCodebaseFamilyPennMUSH;
      
      [self _log: @"Analyzer: MSSP identifies as PennMUSH."];
    }
    else if ([valueString rangeOfString: @"Evennia"].location != NSNotFound)
    {
      _definitiveCodebaseFound = YES;
      _codebase = MUCodebaseEvennia;
      _codebaseFamily = MUCodebaseFamilyEvennia;

      [self _log: @"Analyzer: MSSP identifies as Evennia."];
    }
    else if ([valueString rangeOfString: @"Diku"].location != NSNotFound)
    {
      _definitiveCodebaseFound = YES;
      _codebase = MUCodebaseDikuMUD;
      _codebaseFamily = MUCodebaseFamilyDikuMUD;

      [self _log: @"Analyzer: MSSP identifies as DikuMUD."];
    }
  }
}

- (void) notePrompt: (NSAttributedString *) promptString
{
  [self noteTextString: promptString];
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

- (void) noteTextString: (NSAttributedString *) attributedString
{
  // TODO: Make this use regex instead, it's probably faster. Note we can't use NSRegularExpression because we run on
  // 10.6.
  
  if (_definitiveCodebaseFound)
    return;

  NSString *lowercaseString = attributedString.string.lowercaseString;

  if (self.codebaseFamily == MUCodebaseFamilyUnknown)
  {
    // It's easy for people to talk about other codebases in chat, and we don't want to reset the heuristic every time
    // somebody does because that would be awful. Therefore if we have any guess at all as to what we're running on, we
    // shouldn't do textual matching anymore. We're hoping this is sent early, in the connect banner for example.
    
    if ([lowercaseString rangeOfString: @"mud client test server"].location != NSNotFound)
    {
      _codebase = MUCodebaseMCTS;
      _codebaseFamily = MUCodebaseFamilyMCTS;
      
      [self _log: @"Analyzer: Guessing StickyMUSH from received text."];
    }
    else if ([lowercaseString rangeOfString: @"stickymush"].location != NSNotFound)
    {
      _codebase = MUCodebaseStickyMUSH;
      _codebaseFamily = MUCodebaseFamilyPennMUSH;
      
      [self _log: @"Analyzer: Guessing StickyMUSH from received text."];
    }
    else if ([lowercaseString rangeOfString: @"evennia"].location != NSNotFound)
    {
      _codebase = MUCodebaseEvennia;
      _codebaseFamily = MUCodebaseFamilyEvennia;

      [self _log: @"Analyzer: Guessing Evennia from received text."];
    }
    else if ([lowercaseString rangeOfString: @"pennmush"].location != NSNotFound)
    {
      _codebase = MUCodebasePennMUSH;
      _codebaseFamily = MUCodebaseFamilyPennMUSH;
      
      [self _log: @"Analyzer: Guessing PennMUSH from received text."];
    }
    else if ([lowercaseString rangeOfString: @"rhost"].location != NSNotFound)
    {
      _codebase = MUCodebaseRhostMUSH;
      _codebaseFamily = MUCodebaseFamilyTinyMUSH;
      
      [self _log: @"Analyzer: Guessing RhostMUSH from received text."];
    }
    else if ([lowercaseString rangeOfString: @"mux"].location != NSNotFound)
    {
      _codebase = MUCodebaseTinyMUX;
      _codebaseFamily = MUCodebaseFamilyTinyMUSH;
      
      [self _log: @"Analyzer: Guessing TinyMUX from received text."];
    }
    else if ([lowercaseString rangeOfString: @"muck"].location != NSNotFound)
    {
      _codebase = MUCodebaseTinyMUCK;
      _codebaseFamily = MUCodebaseFamilyTinyMUCK;
      
      [self _log: @"Analyzer: Guessing TinyMUCK from received text."];
    }
    else if ([lowercaseString rangeOfString: @"tinybit"].location != NSNotFound
             || [lowercaseString rangeOfString: @"8bit"].location != NSNotFound)
    {
      _codebase = MUCodebaseTinyBitMUSH;
      _codebaseFamily = MUCodebaseFamilyPennMUSH;
      
      [self _log: @"Analyzer: Guessing TinyBit MUSH from received text."];
    }
    else if ([lowercaseString rangeOfString: @"tinymush"].location != NSNotFound)
    {
      _codebase = MUCodebaseTinyMUSH;
      _codebaseFamily = MUCodebaseFamilyTinyMUSH;
      
      [self _log: @"Analyzer: Guessing TinyMUSH from received text."];
    }
    else if ([lowercaseString rangeOfString: @"dgd"].location != NSNotFound)
    {
      _codebase = MUCodebaseLPMUDWithDGD;
      _codebaseFamily = MUCodebaseFamilyGenericMUD;
      
      [self _log: @"Analyzer: Guessing LPMUD with DGD from received text."];
    }
    else if ([lowercaseString rangeOfString: @"lpmud"].location != NSNotFound)
    {
      _codebase = MUCodebaseLPMUD;
      _codebaseFamily = MUCodebaseFamilyGenericMUD;
      
      [self _log: @"Analyzer: Guessing LPMUD from received text."];
    }
    else if ([lowercaseString rangeOfString: @"merc"].location != NSNotFound)
    {
      _codebase = MUCodebaseMercMUD;
      _codebaseFamily = MUCodebaseFamilyDikuMUD;
      
      [self _log: @"Analyzer: Guessing Merc MUD from received text."];
    }
    else if ([lowercaseString rangeOfString: @"diku"].location != NSNotFound)
    {
      _codebase = MUCodebaseDikuMUD;
      _codebaseFamily = MUCodebaseFamilyDikuMUD;

      [self _log: @"Analyzer: Guessing DikuMUD from received text."];
    }
    else if ([lowercaseString rangeOfString: @"mud"].location != NSNotFound)
    {
      _codebaseFamily = MUCodebaseFamilyGenericMUD;
      
      [self _log: @"Analyzer: Guessing generic MUD from received text."];
    }
    else if ([lowercaseString rangeOfString: @"mush"].location != NSNotFound)
    {
      _codebaseFamily = MUCodebaseFamilyTinyMUSH;
      
      [self _log: @"Analyzer: Guessing generic TinyMUSH from received text."];
    }
  }
}

- (void) reset
{
  _definitiveCodebaseFound = NO;
  _codebase = MUCodebaseUnknown;
  _codebaseFamily = MUCodebaseFamilyUnknown;
}

#pragma mark - Private methods

- (void) _log: (NSString *) message, ...
{
  va_list args;
  va_start (args, message);
  
  [self.delegate log: message arguments: args];
  
  va_end (args);
}

@end
