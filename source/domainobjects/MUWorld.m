//
// MUWorld.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUSocketFactory.h"
#import "MUWorld.h"
#import "MUConstants.h"
#import "MUPlayer.h"
#import "MUCodingService.h"

static const int32_t currentWorldVersion = 7;

@implementation MUWorld

@synthesize hostname, port, url;
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
  
  self.hostname = newHostname;
  self.port = newPort;
  self.url = newURL;
  
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
                       port: [NSNumber numberWithInt: 0]
                        URL: @""
                    players: nil];
}


#pragma mark -
#pragma mark Actions

- (MUMUDConnection *) newTelnetConnectionWithDelegate: (NSObject <MUMUDConnectionDelegate> *) delegate
{
  return [MUMUDConnection telnetWithHostname: self.hostname port: self.port.intValue delegate: delegate];
}

#pragma mark -
#pragma mark Property method implementations

- (NSString *) uniqueIdentifier
{
  NSMutableString *result = [NSMutableString stringWithString: @"world:"];
  NSArray *tokens = [self.name componentsSeparatedByString: @" "];
  
  if (tokens.count > 0)
  {
    [result appendFormat: @"%@", [[tokens objectAtIndex: 0] lowercaseString]];
    
    for (NSUInteger i = 1; i < tokens.count; i++)
      [result appendFormat: @".%@", [[tokens objectAtIndex: i] lowercaseString]];
  }
  return result;
}

- (NSString *) windowTitle
{
  return [NSString stringWithFormat: @"%@", self.name];
}

#pragma mark -
#pragma mark NSCoding protocol

- (void) encodeWithCoder: (NSCoder *) encoder
{
  [encoder encodeInt32: currentWorldVersion forKey: @"version"];
  
  [encoder encodeObject: self.name forKey: @"name"];
  [encoder encodeObject: self.hostname forKey: @"hostname"];
  [encoder encodeInt: [self.port intValue] forKey: @"port"];
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
    self.hostname = [decoder decodeObjectForKey: @"hostname"];
  }
  else
  {
    self.name = [decoder decodeObjectForKey: @"worldName"];
    self.hostname = [decoder decodeObjectForKey: @"worldHostname"];
  }
  
  if (version >= 6)
    self.port = [[NSNumber alloc] initWithInt: [decoder decodeIntForKey: @"port"]];
  else if (version == 5)
    self.port = [decoder decodeObjectForKey: @"port"];
  else
    self.port = [decoder decodeObjectForKey: @"worldPort"];
  
  if (version >= 7)
    self.children = [decoder decodeObjectForKey: @"children"];
  else
    self.children = [decoder decodeObjectForKey: @"players"];
  
  if (version >= 5)
    self.url = [decoder decodeObjectForKey: @"URL"];
  else if (version >= 1)
    self.url = [decoder decodeObjectForKey: @"worldURL"];
  else
    self.url = @"";
  
  return self;
}

#pragma mark -
#pragma mark NSCopying protocol

- (id) copyWithZone: (NSZone *) zone
{
  return [[MUWorld allocWithZone: zone] initWithName: self.name
                                            hostname: self.hostname
                                                port: self.port
                                                 URL: self.url
                                             players: self.children];
}

@end
