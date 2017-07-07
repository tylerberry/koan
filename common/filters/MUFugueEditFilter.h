//
// MUFugueEditFilter.h
//
// Copyright (c) 2013 3James Software.
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

+ (instancetype) filterWithProfile: (MUProfile *) newProfile
                          delegate: (NSObject <MUFugueEditFilterDelegate> *) newDelegate;

- (instancetype) initWithProfile: (MUProfile *) newProfile
                        delegate: (NSObject <MUFugueEditFilterDelegate> *) newDelegate;

@end
