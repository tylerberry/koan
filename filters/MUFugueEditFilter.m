//
// MUFugueEditFilter.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUFugueEditFilter.h"

@implementation MUFugueEditFilter
{
  MUProfile *_profile;
}

+ (MUFilter *) filterWithProfile: (MUProfile *) newProfile
                        delegate: (NSObject <MUFugueEditFilterDelegate> *) newDelegate
{
  return [[self alloc] initWithProfile: newProfile delegate: newDelegate];
}

- (id) initWithProfile: (MUProfile *) newProfile
              delegate: (NSObject <MUFugueEditFilterDelegate> *) newDelegate
{
  if (!(self = [super init]))
    return nil;
  
  _profile = newProfile;
  _delegate = newDelegate;
  return self;
}

- (id) init
{
  return [self initWithProfile: nil delegate: nil];
}

- (NSAttributedString *) filterCompleteLine: (NSAttributedString *) attributedString
{
  NSString *plainString = attributedString.string;
  
  if (_profile && _profile.player.fugueEditPrefix && [plainString hasPrefix: _profile.player.fugueEditPrefix])
  {
    [self.delegate setInputViewString: [[plainString substringFromIndex: _profile.player.fugueEditPrefix.length]
                                        stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    
    return [[NSAttributedString alloc] initWithString: @""];
  }
  else
    return attributedString;
}

- (NSAttributedString *) filterPartialLine: (NSAttributedString *) attributedString
{
  return attributedString;
}

@end
