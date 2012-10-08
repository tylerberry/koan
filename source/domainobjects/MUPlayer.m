//
// MUPlayer.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUPlayer.h"

static const int32_t currentPlayerVersion = 1;

@implementation MUPlayer

@synthesize password;
@dynamic loginString, uniqueIdentifier, windowTitle;

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
  
  password = [newPassword copy];
  
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

- (NSString *) uniqueIdentifier
{
  NSMutableString *result = [NSMutableString stringWithString: @"player:"];
  NSArray *tokens = [self.name componentsSeparatedByString: @" "];
  
  if (tokens.count > 0)
  {
    [result appendFormat: @"%@", [tokens[0] lowercaseString]];
    
    for (NSUInteger i = 1; i < tokens.count; i++)
      [result appendFormat: @".%@", [tokens[i] lowercaseString]];
  }
  return result;
}

- (NSString *) windowTitle
{
  // FIXME: This is not the right way to get the window title.
  return [NSString stringWithFormat: @"%@ @ %@", self.name, self.parent.name];
}

#pragma mark - NSCoding protocol

- (void) encodeWithCoder: (NSCoder *) encoder
{
  [encoder encodeInt32: currentPlayerVersion forKey: @"version"];
  
  [encoder encodeObject: self.name forKey: @"name"];
  [encoder encodeObject: self.password forKey: @"password"];
}

- (id) initWithCoder: (NSCoder *) decoder
{
  if (!(self = [super initWithName: nil children: nil]))
    return nil;
  
  // int32_t version = [decoder decodeInt32ForKey: @"version"];
  
  self.name = [decoder decodeObjectForKey: @"name"];
  password = [decoder decodeObjectForKey: @"password"];
  
  return self;
}

#pragma mark - NSCopying protocol

- (id) copyWithZone: (NSZone *) zone
{
  return [[MUPlayer allocWithZone: zone] initWithName: self.name
                                             password: self.password];
}

@end
