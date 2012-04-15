//
// MUFugueEditFilter.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>
#import <MUFilter.h>

@interface MUFugueEditFilter : MUFilter
{
  id __unsafe_unretained delegate;
}

@property (unsafe_unretained, nonatomic) id delegate;

+ (id) filterWithDelegate: (id) newDelegate;

- (id) initWithDelegate: (id) newDelegate;

@end

#pragma mark -

@interface NSObject (MUFugueEditFilterDelegate)

- (void) setInputViewString: (NSString *) text;

@end
