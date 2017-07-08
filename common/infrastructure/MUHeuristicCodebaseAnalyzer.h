//
// MUHeuristicCodebaseAnalyzer.h
//
// Copyright (c) 2013 3James Software.
//

typedef NS_ENUM (NSInteger, MUCodebase)
{
  MUCodebaseMCTS,
  MUCodebaseTinyMUX,
  MUCodebaseTinyMUSH,
  MUCodebasePennMUSH,
  MUCodebaseStickyMUSH,
  MUCodebaseTinyBitMUSH,
  MUCodebaseRhostMUSH,
  MUCodebaseTinyMUCK,
  MUCodebaseEvennia,
  MUCodebaseSlothMUD,
  MUCodebaseMercMUD,
  MUCodebaseDikuMUD,
  MUCodebaseLPMUD,
  MUCodebaseLPMUDWithDGD,
  MUCodebaseUnknown
};

typedef NS_ENUM (NSInteger, MUCodebaseFamily)
{
  MUCodebaseFamilyMCTS,
  MUCodebaseFamilyTinyMUSH,
  MUCodebaseFamilyPennMUSH,
  MUCodebaseFamilyTinyMUCK,
  MUCodebaseFamilyEvennia,
  MUCodebaseFamilyDikuMUD,
  MUCodebaseFamilyGenericMUD,
  MUCodebaseFamilyUnknown
};

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

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithDelegate: (NSObject <MUHeuristicCodebaseAnalyzerDelegate> *) newDelegate NS_DESIGNATED_INITIALIZER;

- (void) noteMSSPVariable: (NSString *) variable value: (NSString *) value;
- (void) notePrompt: (NSAttributedString *) promptString;
- (void) noteTelnetDo: (uint8_t) byte;
- (void) noteTelnetDont: (uint8_t) byte;
- (void) noteTelnetWill: (uint8_t) byte;
- (void) noteTelnetWont: (uint8_t) byte;
- (void) noteTextString: (NSAttributedString *) attributedString;

- (void) reset;

@end
