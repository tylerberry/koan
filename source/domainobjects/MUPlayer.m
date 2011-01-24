//
// MUPlayer.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUPlayer.h"
#import "MUCodingService.h"

@implementation MUPlayer

@synthesize password;
@dynamic loginString, uniqueIdentifier, windowTitle;

+ (MUPlayer *) playerWithName: (NSString *) newName
  									 password: (NSString *) newPassword
{
  return [[[self alloc] initWithName: newName password: newPassword] autorelease];
}

- (id) initWithName: (NSString *) newName
           password: (NSString *) newPassword
{
  if (!(self = [super initWithName: newName children: nil]))
    return nil;
  
  password = newPassword;
  
  return self;
}

- (id) init
{
  return [self initWithName: @"New player" password: @""];
}

- (void) dealloc
{
  [password release];
  [super dealloc];
}

#pragma mark -
#pragma mark Property method implementations

- (NSString *) loginString
{
  if (!self.name)
  	return nil;

  NSRange whitespaceRange = [self.name rangeOfCharacterFromSet: [NSCharacterSet whitespaceCharacterSet]];
  
  if (self.password && [self.password length] > 0)
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
  
  if ([tokens count] > 0)
  {
    [result appendFormat: @"%@", [[tokens objectAtIndex: 0] lowercaseString]];
    
    for (unsigned i = 1; i < [tokens count]; i++)
      [result appendFormat: @".%@", [[tokens objectAtIndex: i] lowercaseString]];
  }
  return result;
}

- (NSString *) windowTitle
{
  // FIXME: WROOONG.
  return [NSString stringWithFormat: @"%@ @ %@", self.name, self.parent.name];
}

#pragma mark -
#pragma mark NSCoding protocol

- (void) encodeWithCoder: (NSCoder *) encoder
{
  [MUCodingService encodePlayer: self withCoder: encoder];
}

- (id) initWithCoder: (NSCoder *) decoder
{
  if (!(self = [super init]))
    return nil;
  
  [MUCodingService decodePlayer: self withCoder: decoder];
  
  return self;
}

#pragma mark -
#pragma mark NSCopying protocol

- (id) copyWithZone: (NSZone *) zone
{
  return [[MUPlayer allocWithZone: zone] initWithName: self.name
                                             password: self.password];
}

@end
