//
// MUHeuristicCodebaseAnalyzer.h
//
// Copyright (c) 2013 3James Software.
//

typedef enum MUCodebase
{
  MUCodebaseTinyMUX,
  MUCodebaseTinyMUSH,
  MUCodebasePennMUSH,
  MUCodebaseStickyMUSH,
  MUCodebaseRhostMUSH,
  MUCodebaseLPMUD,
  MUCodebaseLPMUDWithDGD,
  MUCodebaseUnknown
} MUCodebase;

typedef enum MUCodebaseFamily
{
  MUCodebaseFamilyTinyMUSH,
  MUCodebaseFamilyPennMUSH,
  MUCodebaseFamilyMUD,
  MUCodebaseFamilyUnknown
} MUCodebaseFamily;

@interface MUHeuristicCodebaseAnalyzer : NSObject

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
