//
// MUWorld.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUWorld.h"
#import "MUPlayer.h"
#import "MUSocketFactory.h"

static const int32_t currentWorldVersion = 9;

@implementation MUWorld

@dynamic windowTitle;

+ (instancetype) worldWithName: (NSString *) name
                      hostname: (NSString *) hostname
                          port: (NSNumber *) port
                      forceTLS: (BOOL) forceTLS
                           URL: (NSString *) url
                      children: (NSArray *) children
{
  return [[self alloc] initWithName: name
                           hostname: hostname
                               port: port
                           forceTLS: forceTLS
                                URL: url
                           children: children];
}

+ (instancetype) worldWithHostname: (NSString *) hostname
                              port: (NSNumber *) port
                          forceTLS: (BOOL) forceTLS
{
  return [[self alloc] initWithName: hostname
                           hostname: hostname
                               port: port
                           forceTLS: forceTLS
                                URL: nil
                           children: nil];
}

- (instancetype) initWithName: (NSString *) name
                     hostname: (NSString *) hostname
                         port: (NSNumber *) port
                     forceTLS: (BOOL) forceTLS
                          URL: (NSString *) url
                     children: (NSArray *) children
{
  if (!(self = [super initWithName: name children: children]))
    return nil;
  
  _hostname = [hostname copy];
  _port = [port copy];
  _forceTLS = forceTLS;
  _url = [url copy];
  
  return self;
}

- (instancetype) initWithHostname: (NSString *) hostname
                             port: (NSNumber *) port
                         forceTLS: (BOOL) forceTLS
{
  return [self initWithName: hostname
                   hostname: hostname
                       port: port
                   forceTLS: forceTLS
                        URL: @""
                   children: nil];
}

- (instancetype) init
{
  return [self initWithName: @"New world"
                   hostname: @""
                       port: @0
                   forceTLS: NO
                        URL: @""
                   children: nil];
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

#pragma mark - NSCopying protocol

- (id) copyWithZone: (NSZone *) zone
{
  return [[MUWorld allocWithZone: zone] initWithName: self.name
                                            hostname: self.hostname
                                                port: self.port
                                            forceTLS: self.forceTLS
                                                 URL: self.url
                                            children: self.children];
}

#pragma mark - NSSecureCoding protocol

- (void) encodeWithCoder: (NSCoder *) encoder
{
  [super encodeWithCoder: encoder];
  
  [encoder encodeInt32: currentWorldVersion forKey: @"worldVersion"];
  
  [encoder encodeObject: self.hostname forKey: @"hostname"];
  [encoder encodeInt: self.port.intValue forKey: @"port"];
  [encoder encodeBool: self.forceTLS forKey: @"forceTLS"];
  [encoder encodeObject: self.url forKey: @"URL"];
}

- (instancetype) initWithCoder: (NSCoder *) decoder
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
    self.name = [decoder decodeObjectOfClass: [NSString class] forKey: @"worldName"];
    _hostname = [decoder decodeObjectOfClass: [NSString class] forKey: @"worldHostname"];
  }
  else if (version < 8)
  {
    self.name = [decoder decodeObjectOfClass: [NSString class] forKey: @"name"];
    _hostname = [decoder decodeObjectOfClass: [NSString class] forKey: @"hostname"];
  }
  else
  {
    _hostname = [decoder decodeObjectOfClass: [NSString class] forKey: @"hostname"];
  }
  
  if (version == 7)
    self.children = [decoder decodeObjectOfClass: [NSArray class] forKey: @"children"];
  else if (version < 7)
    self.children = [decoder decodeObjectOfClass: [NSArray class] forKey: @"players"];
  
  if (version >= 6)
    _port = @([decoder decodeIntForKey: @"port"]);
  else if (version == 5)
    _port = [decoder decodeObjectOfClass: [NSNumber class] forKey: @"port"];
  else
    _port = [decoder decodeObjectOfClass: [NSNumber class] forKey: @"worldPort"];
  
  if (version >= 5)
    _url = [decoder decodeObjectOfClass: [NSString class] forKey: @"URL"];
  else if (version >= 1)
    _url = [decoder decodeObjectOfClass: [NSString class] forKey: @"worldURL"];
  else
    _url = @"";
  
  if (version >= 9)
    _forceTLS = [decoder decodeBoolForKey: @"forceTLS"];
  else
    _forceTLS = NO;

  return self;
}

@end
