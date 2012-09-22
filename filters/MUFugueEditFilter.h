//
// MUFugueEditFilter.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>
#import <MUFilter.h>

@protocol MUFugueEditFilterDelegate

@required
- (void) setInputViewString: (NSString *) text;

@end

#pragma mark -

@interface MUFugueEditFilter : MUFilter

@property (weak, nonatomic) NSObject <MUFugueEditFilterDelegate> *delegate;

+ (id) filterWithDelegate: (NSObject <MUFugueEditFilterDelegate> *) newDelegate;

- (id) initWithDelegate: (NSObject <MUFugueEditFilterDelegate> *) newDelegate;

@end
