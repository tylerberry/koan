//
// MUWorld.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUWorld.h"
#import "MUPlayer.h"
#import "MUSocketFactory.h"

static const int32_t currentWorldVersion = 8;

@implementation MUWorld

@dynamic windowTitle;

+ (MUWorld *) worldWithName: (NSString *) name
                   hostname: (NSString *) hostname
                       port: (NSNumber *) port
                        URL: (NSString *) url
                   children: (NSArray *) children
{
  return [[self alloc] initWithName: name
                           hostname: hostname
                               port: port
                                URL: url
                           children: children];
}

+ (MUWorld *) worldWithHostname: (NSString *) hostname
                           port: (NSNumber *) port
{
  return [[self alloc] initWithName: hostname
                           hostname: hostname
                               port: port
                                URL: nil
                           children: nil];
}

- (id) initWithName: (NSString *) name
           hostname: (NSString *) hostname
               port: (NSNumber *) port
                URL: (NSString *) url
           children: (NSArray *) children
{
  if (!(self = [super initWithName: name children: children]))
    return nil;
  
  _hostname = [hostname copy];
  _port = [port copy];
  _url = [url copy];
  
  return self;
}

- (id) initWithHostname: (NSString *) hostname
                   port: (NSNumber *) port
{
  return [self initWithName: hostname
                   hostname: hostname
                       port: port
                        URL: @""
                   children: nil];
}

- (id) init
{
  return [self initWithName: @"New world"
                   hostname: @""
                       port: @0
                        URL: @""
                   children: nil];
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

- (NSString *) windowTitle
{
  return [NSString stringWithFormat: @"%@", self.name];
}

#pragma mark - NSCoding protocol

- (void) encodeWithCoder: (NSCoder *) encoder
{
  [super encodeWithCoder: encoder];
  
  [encoder encodeInt32: currentWorldVersion forKey: @"worldVersion"];
  
  [encoder encodeObject: self.hostname forKey: @"hostname"];
  [encoder encodeInt: self.port.intValue forKey: @"port"];
  [encoder encodeObject: self.url forKey: @"URL"];
}

- (id) initWithCoder: (NSCoder *) decoder
{
  int32_t version = [decoder decodeInt32ForKey: @"worldVersion"];
  
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
  
  if (version < 5)
  {
    self.name = [decoder decodeObjectForKey: @"worldName"];
    _hostname = [decoder decodeObjectForKey: @"worldHostname"];
  }
  else if (version < 8)
  {
    self.name = [decoder decodeObjectForKey: @"name"];
    _hostname = [decoder decodeObjectForKey: @"hostname"];
  }
  else
  {
    _hostname = [decoder decodeObjectForKey: @"hostname"];
  }
  
  if (version == 7)
    self.children = [decoder decodeObjectForKey: @"children"];
  else if (version < 7)
    self.children = [decoder decodeObjectForKey: @"players"];
  
  if (version >= 6)
    _port = @([decoder decodeIntForKey: @"port"]);
  else if (version == 5)
    _port = [decoder decodeObjectForKey: @"port"];
  else
    _port = [decoder decodeObjectForKey: @"worldPort"];
  
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
                                            children: self.children];
}

@end
