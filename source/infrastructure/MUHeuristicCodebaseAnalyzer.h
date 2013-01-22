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


@protocol MUHeuristicCodebaseAnalyzerDelegate

@required
- (void) log: (NSString *) message arguments: (va_list) args;

@end

#pragma mark -

@interface MUHeuristicCodebaseAnalyzer : NSObject

@property (weak) NSObject <MUHeuristicCodebaseAnalyzerDelegate> *delegate;

@property (readonly) MUCodebase codebase;
@property (readonly) MUCodebaseFamily codebaseFamily;
@property (readonly) BOOL shouldSuppressGoAhead;

- (id) initWithDelegate: (NSObject <MUHeuristicCodebaseAnalyzerDelegate> *) newDelegate;

- (void) noteMSSPVariable: (NSString *) variable value: (NSString *) value;
- (void) notePrompt: (NSString *) promptString;
- (void) noteTelnetDo: (uint8_t) byte;
- (void) noteTelnetDont: (uint8_t) byte;
- (void) noteTelnetWill: (uint8_t) byte;
- (void) noteTelnetWont: (uint8_t) byte;
- (void) noteTextLine: (NSString *) textString;

- (void) reset;

@end
