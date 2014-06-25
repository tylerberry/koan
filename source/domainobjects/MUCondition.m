//
// MUCondition.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUCondition.h"

@implementation MUCondition

- (instancetype) initWithPredicate: (NSPredicate *) predicate actions: (NSArray *) actions
{
  if (!(self = [super init]))
    return nil;

  _predicate = [predicate copy];
  _actions = [actions copy];

  return self;
}

- (void) applyToMutableAttributedString: (NSMutableAttributedString *) mutableAttributedString
{
  if ([self.predicate evaluateWithObject: mutableAttributedString.string])
    ;

  return;
}

#pragma mark - NSCopying protocol

- (id) copyWithZone: (NSZone *) zone
{
  return [[MUCondition alloc] initWithPredicate: self.predicate actions: self.actions];
}

#pragma mark - NSSecureCoding protocol

+ (BOOL) supportsSecureCoding
{
  return YES;
}

- (void) encodeWithCoder: (NSCoder *) coder
{
  [coder encodeObject: self.predicate forKey: @"predicate"];
  [coder encodeObject: self.actions forKey: @"actions"];
}

- (instancetype) initWithCoder: (NSCoder *) decoder
{
  if (!(self = [self initWithPredicate: [decoder decodeObjectOfClass: [NSPredicate class] forKey: @"predicate"]
                               actions: [decoder decodeObjectOfClass: [NSArray class] forKey: @"actions"]]))
    return nil;

  return self;
}

@end
