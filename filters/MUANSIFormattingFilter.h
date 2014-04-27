//
// MUANSIFormattingFilter.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUFilter.h"

#import "MUProfile.h"

typedef enum MUANSICommands
{
  MUANSIXtermSetWindowTitle = '\007',
  MUANSIEraseData = 'J',
  MUANSISelectGraphicRendition = 'm'
} MUANSICommand;

@protocol MUANSIFormattingFilterDelegate

@optional
- (void) clearScreen;

@end

#pragma mark -

@interface MUANSIFormattingFilter : MUFilter

@property (weak) NSObject <MUANSIFormattingFilterDelegate> *delegate;

+ (MUFilter *) filterWithProfile: (MUProfile *) newProfile
                        delegate: (NSObject <MUANSIFormattingFilterDelegate> *) newDelegate;

- (id) initWithProfile: (MUProfile *) newProfile
              delegate: (NSObject <MUANSIFormattingFilterDelegate> *) newDelegate;

@end
