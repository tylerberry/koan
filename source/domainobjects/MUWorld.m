//
// MUWorld.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUWorld.h"
#import "MUPlayer.h"
#import "MUSocketFactory.h"

static const int32_t currentWorldVersion = 7;

@implementation MUWorld

@dynamic uniqueIdentifier, windowTitle;

+ (MUWorld *) worldWithName: (NSString *) newName
  								 hostname: (NSString *) newHostname
  										 port: (NSNumber *) newPort
  											URL: (NSString *) newURL
  									players: (NSArray *) newPlayers
{
  return [[self alloc] initWithName: newName
  													hostname: newHostname
  															port: newPort
  															 URL: newURL
  													 players: newPlayers];
}

+ (MUWorld *) worldWithHostname: (NSString *) newHostname
                           port: (NSNumber *) newPort
{
  return [self worldWithName: newHostname
                    hostname: newHostname
                        port: newPort
                         URL: @""
                     players: nil];
}

- (id) initWithName: (NSString *) newName
           hostname: (NSString *) newHostname
               port: (NSNumber *) newPort
                URL: (NSString *) newURL
            players: (NSArray *) newPlayers
{
  if (!(self = [super initWithName: newName children: newPlayers]))
    return nil;
  
  _hostname = [newHostname copy];
  _port = [newPort copy];
  _url = [newURL copy];
  
  return self;
}

- (id) initWithHostname: (NSString *) newHostname
                   port: (NSNumber *) newPort
{
  return [self initWithName: newHostname
                   hostname: newHostname
                       port: newPort
                        URL: @""
                    players: nil];
}

- (id) init
{
  return [self initWithName: @"New world"
                   hostname: @""
                       port: @0
                        URL: @""
                    players: nil];
}


#pragma mark - Actions

- (MUMUDConnection *) newTelnetConnectionWithDelegate: (NSObject <MUMUDConnectionDelegate> *) delegate
{
  return [MUMUDConnection telnetWithHostname: self.hostname port: self.port.intValue delegate: delegate];
}

#pragma mark - Property method implementations

- (NSImage *) icon
{
  return [NSImage imageNamed: @"NSNetwork"];
}

- (NSString *) uniqueIdentifier
{
  NSMutableString *result = [NSMutableString stringWithString: @"world:"];
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
  return [NSString stringWithFormat: @"%@", self.name];
}

#pragma mark - NSCoding protocol

- (void) encodeWithCoder: (NSCoder *) encoder
{
  [encoder encodeInt32: currentWorldVersion forKey: @"version"];
  
  [encoder encodeObject: self.name forKey: @"name"];
  [encoder encodeObject: self.hostname forKey: @"hostname"];
  [encoder encodeInt: self.port.intValue forKey: @"port"];
  [encoder encodeObject: self.children forKey: @"children"];
  [encoder encodeObject: self.url forKey: @"URL"];
}

- (id) initWithCoder: (NSCoder *) decoder
{
  if (!(self = [super initWithName: nil children: nil]))
    return nil;
  
  int32_t version = [decoder decodeInt32ForKey: @"version"];
  
  if (version >= 5)
  {
    self.name = [decoder decodeObjectForKey: @"name"];
    _hostname = [decoder decodeObjectForKey: @"hostname"];
  }
  else
  {
    self.name = [decoder decodeObjectForKey: @"worldName"];
    _hostname = [decoder decodeObjectForKey: @"worldHostname"];
  }
  
  if (version >= 6)
    _port = @([decoder decodeIntForKey: @"port"]);
  else if (version == 5)
    _port = [decoder decodeObjectForKey: @"port"];
  else
    _port = [decoder decodeObjectForKey: @"worldPort"];
  
  if (version >= 7)
    self.children = [decoder decodeObjectForKey: @"children"];
  else
    self.children = [decoder decodeObjectForKey: @"players"];
  
  if (version >= 5)
    _url = [decoder decodeObjectForKey: @"URL"];
  else if (version >= 1)
    _url = [decoder decodeObjectForKey: @"worldURL"];
  else
    _url = @"";
  
  return self;
}

#pragma mark - NSCopying protocol

- (id) copyWithZone: (NSZone *) zone
{
  return [[MUWorld allocWithZone: zone] initWithName: self.name
                                            hostname: self.hostname
                                                port: self.port
                                                 URL: self.url
                                             players: self.children];
}

@end
