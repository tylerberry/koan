//
// MUPredicateCondition.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUPredicateCondition.h"

@implementation MUPredicateCondition

@synthesize name = _name;

- (instancetype) initWithName: (NSString *) name predicate: (NSPredicate *) predicate actions: (NSArray *) actions
{
  if (!(self = [super initWithName: name]))
    return nil;

  _predicate = [predicate copy];
  _actions = [actions mutableCopy];

  return self;
}

- (instancetype) initWithName: (NSString *) name
{
  return [self initWithName: name predicate: nil actions: @[]];
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
  return [[MUPredicateCondition alloc] initWithName: self.name predicate: self.predicate actions: self.actions];
}

#pragma mark - NSSecureCoding protocol

+ (BOOL) supportsSecureCoding
{
  return YES;
}

- (void) encodeWithCoder: (NSCoder *) coder
{
  [coder encodeObject: self.name forKey: @"name"];
  [coder encodeObject: self.predicate forKey: @"predicate"];
  [coder encodeObject: self.actions forKey: @"actions"];
}

- (instancetype) initWithCoder: (NSCoder *) decoder
{
  if (!(self = [self initWithName: [decoder decodeObjectOfClass: [NSString class] forKey: @"name"]
                        predicate: [decoder decodeObjectOfClass: [NSPredicate class] forKey: @"predicate"]
                          actions: [decoder decodeObjectOfClass: [NSArray class] forKey: @"actions"]]))
    return nil;

  return self;
}

@end
