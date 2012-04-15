//
// MUHeuristicCodebaseAnalyzer.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>

typedef enum MUCodebase
{
  MUCodebaseTinyMUX,
  MUCodebaseTinyMUSH,
  MUCodebasePennMUSH,
  MUCodebaseRhostMUSH,
  MUCodebaseLPMUD,
  MUCodebaseLPMUDWithDGD,
  MUCodebaseUnknown
} MUCodebase;

typedef enum MUCodebaseFamily
{
  MUCodebaseFamilyMUSH,
  MUCodebaseFamilyMUD,
  MUCodebaseFamilyUnknown
} MUCodebaseFamily;

@interface MUHeuristicCodebaseAnalyzer : NSObject
{
  MUCodebase codebase;
  MUCodebaseFamily codebaseFamily;
  BOOL definitiveCodebaseFound;
}

@property (assign, nonatomic) MUCodebase codebase;
@property (assign, nonatomic) MUCodebaseFamily codebaseFamily;
@property (readonly) BOOL shouldSuppressGoAhead;

- (void) noteMSSPVariable: (NSString *) variable value: (NSString *) value;
- (void) noteTelnetDo: (uint8_t) byte;
- (void) noteTelnetDont: (uint8_t) byte;
- (void) noteTelnetWill: (uint8_t) byte;
- (void) noteTelnetWont: (uint8_t) byte;
- (void) noteTextLine: (NSString *) text;

@end
