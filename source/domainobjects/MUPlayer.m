//
// MUPlayer.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUPlayer.h"

static const int32_t currentPlayerVersion = 3;

@implementation MUPlayer

@dynamic loginString, windowTitle;

+ (MUPlayer *) playerWithName: (NSString *) newName
  									 password: (NSString *) newPassword
{
  return [[self alloc] initWithName: newName password: newPassword];
}

- (id) initWithName: (NSString *) newName
           password: (NSString *) newPassword
{
  if (!(self = [super initWithName: newName children: nil]))
    return nil;
  
  _password = [newPassword copy];
  
  return self;
}

- (id) init
{
  return [self initWithName: @"New player" password: @""];
}

#pragma mark - Property method implementations

- (NSImage *) icon
{
  return [NSImage imageNamed: @"NSUser"];
}

- (NSString *) loginString
{
  if (!self.name)
  	return nil;
  
  NSRange whitespaceRange = [self.name rangeOfCharacterFromSet: [NSCharacterSet whitespaceCharacterSet]];
  
  if (self.password && self.password.length > 0)
  {
  	if (whitespaceRange.location == NSNotFound)
  		return [NSString stringWithFormat: @"connect %@ %@", self.name, self.password];
  	else
  		return [NSString stringWithFormat: @"connect \"%@\" %@", self.name, self.password];
  }
  else
  {
  	if (whitespaceRange.location == NSNotFound)
  		return [NSString stringWithFormat: @"connect %@", self.name];
  	else
  		return [NSString stringWithFormat: @"connect \"%@\"", self.name];
  }
}

- (NSString *) windowTitle
{
  // FIXME: This is not the right way to get the window title.
  return [NSString stringWithFormat: @"%@ @ %@", self.name, self.parent.name];
}

#pragma mark - NSCoding protocol

- (void) encodeWithCoder: (NSCoder *) encoder
{
  [super encodeWithCoder: encoder];
  
  [encoder encodeInt32: currentPlayerVersion forKey: @"playerVersion"];
  
  [encoder encodeObject: self.password forKey: @"password"];
  [encoder encodeObject: self.fugueEditPrefix forKey: @"fugueEditPrefix"];
}

- (id) initWithCoder: (NSCoder *) decoder
{
  int32_t version = [decoder decodeInt32ForKey: @"playerVersion"];
  
  if (version != 0)
  {
    if (!(self = [super initWithCoder: decoder]))
      return nil;
  }
  else
  {
    version = [decoder decodeInt32ForKey: @"version"];
    
    if (!(self = [super initWithName: nil children: nil]))
      return nil;
  }
  
  _password = [decoder decodeObjectForKey: @"password"];
  
  if (version == 1)
    self.name = [decoder decodeObjectForKey: @"name"];
  
  if (version >= 3)
    _fugueEditPrefix = [decoder decodeObjectForKey: @"fugueEditPrefix"];
  else
    _fugueEditPrefix = nil;
  
  return self;
}

#pragma mark - NSCopying protocol

- (id) copyWithZone: (NSZone *) zone
{
  MUPlayer *copy = [[MUPlayer allocWithZone: zone] initWithName: self.name
                                                       password: self.password];
  
  copy.fugueEditPrefix = self.fugueEditPrefix;
  
  return copy;
}

@end
