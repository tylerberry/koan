//
// MUFugueEditFilter.h
//
// Copyright (c) 2012 3James Software.
//

#import "MUFilter.h"

#import "MUProfile.h"

@protocol MUFugueEditFilterDelegate

@required
- (void) setInputViewString: (NSString *) text;

@end

#pragma mark -

@interface MUFugueEditFilter : MUFilter

@property (weak, nonatomic) NSObject <MUFugueEditFilterDelegate> *delegate;

+ (MUFilter *) filterWithProfile: (MUProfile *) newProfile
                        delegate: (NSObject <MUFugueEditFilterDelegate> *) newDelegate;

- (id) initWithProfile: (MUProfile *) newProfile
              delegate: (NSObject <MUFugueEditFilterDelegate> *) newDelegate;

@end
