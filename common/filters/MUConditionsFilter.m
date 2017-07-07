//
// MUConditionsFilter.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUConditionsFilter.h"

#import "MUCondition.h"

@implementation MUConditionsFilter

- (NSAttributedString *) filterCompleteLine: (NSAttributedString *) attributedString
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSArray *conditions = [defaults arrayForKey: MUPConditions];

  NSMutableAttributedString *mutableAttributedString = [attributedString mutableCopy];

  for (MUCondition *condition in conditions)
    [condition applyToMutableAttributedString: mutableAttributedString];

  return mutableAttributedString;
}

- (NSAttributedString *) filterPartialLine: (NSAttributedString *) attributedString
{
  return attributedString;
}

@end
