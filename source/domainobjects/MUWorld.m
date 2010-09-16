//
// MUWorld.m
//
// Copyright (c) 2010 3James Software.
//

#import "J3SocketFactory.h"
#import "MUWorld.h"
#import "MUConstants.h"
#import "MUPlayer.h"
#import "MUCodingService.h"

static const int32_t currentWorldVersion = 6;

@interface MUWorld (Private)

- (void) postWorldsDidChangeNotification;

@end

#pragma mark -

@implementation MUWorld

@synthesize name, hostname, port, url, isExpanded, players;
@dynamic uniqueIdentifier, windowTitle;

+ (MUWorld *) worldWithName: (NSString *) newName
  								 hostname: (NSString *) newHostname
  										 port: (NSNumber *) newPort
  											URL: (NSString *) newURL
  									players: (NSArray *) newPlayers
{
  return [[[self alloc] initWithName: newName
  													hostname: newHostname
  															port: newPort
  															 URL: newURL
  													 players: newPlayers] autorelease];
}

- (id) initWithName: (NSString *) newName
           hostname: (NSString *) newHostname
               port: (NSNumber *) newPort
                URL: (NSString *) newURL
            players: (NSArray *) newPlayers
{
  if (!(self = [super init]))
    return nil;
  
  name = [newName copy];
  hostname = [newHostname copy];
  port = [newPort copy];
  url = [newURL copy];
  players = newPlayers ? [newPlayers mutableCopy] : [[NSMutableArray alloc] init];
  
  return self;
}

- (id) init
{
  return [self initWithName: @""
                   hostname: @""
                       port: [NSNumber numberWithInt: 0]
                        URL: @""
                    players: nil];
}

- (void) dealloc
{
  [name release];
  [hostname release];
  [port release];
  [url release];
  [players release];
  [super dealloc];
}

#pragma mark -
#pragma mark Array-like accessors for players

- (void) addPlayer: (MUPlayer *) player
{
  if ([self containsPlayer: player])
    return;
  
  [self willChangeValueForKey: @"players"];
  [players addObject: player];
  player.world = self;
  [self didChangeValueForKey: @"players"];
  
  [self postWorldsDidChangeNotification];
}

- (BOOL) containsPlayer: (MUPlayer *) player
{
  return [players containsObject: player];
}

- (int) indexOfPlayer: (MUPlayer *) player
{
  for (unsigned i = 0; i < [players count]; i++)
  {
  	if (player == [players objectAtIndex: i])
  		return (int) i;
  }
  
  return NSNotFound;
}

- (void) insertObject: (MUPlayer *) player inPlayersAtIndex: (unsigned) playerIndex
{
  [self willChangeValueForKey: @"players"];
  player.world = self;
  [players insertObject: player atIndex: playerIndex];
  [self didChangeValueForKey: @"players"];
  
  [self postWorldsDidChangeNotification];
}

- (void) removeObjectFromPlayersAtIndex: (unsigned) playerIndex
{
  [self willChangeValueForKey: @"players"];
  [players removeObjectAtIndex: playerIndex];
  ((MUPlayer *) [players objectAtIndex: playerIndex]).world = nil;
  [self didChangeValueForKey: @"players"];
  
  [self postWorldsDidChangeNotification];
}

- (void) removePlayer: (MUPlayer *) player
{
  [self willChangeValueForKey: @"players"];
  [players removeObject: player];
  player.world = nil;
  [self didChangeValueForKey: @"players"];
  
  [self postWorldsDidChangeNotification];
}

- (void) replacePlayer: (MUPlayer *) oldPlayer withPlayer: (MUPlayer *) newPlayer
{
  for (unsigned i = 0; i < [players count]; i++)
  {
  	MUPlayer *player = [players objectAtIndex: i];
  	
  	if (player != oldPlayer)
      continue;
    
    [self willChangeValueForKey: @"players"];
    newPlayer.world = self;
    [players replaceObjectAtIndex: i withObject: newPlayer];
    oldPlayer.world = nil;
    [self didChangeValueForKey: @"players"];
    
    [self postWorldsDidChangeNotification];
    break;
  }
}

#pragma mark -
#pragma mark Actions

- (J3TelnetConnection *) newTelnetConnectionWithDelegate: (NSObject <J3TelnetConnectionDelegate> *) delegate
{
  return [J3TelnetConnection telnetWithHostname: self.hostname port: [self.port intValue] delegate: delegate];
}

#pragma mark -
#pragma mark Property method implementations

- (NSString *) uniqueIdentifier
{
  NSArray *tokens = [self.name componentsSeparatedByString: @" "];
  NSMutableString *result = [NSMutableString string];

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
  [encoder encodeObject: self.players forKey: @"players"];
  [encoder encodeObject: self.url forKey: @"URL"];
  [encoder encodeBool: self.isExpanded forKey: @"isExpanded"];
}

- (id) initWithCoder: (NSCoder *) decoder
{
  if (!(self = [super init]))
    return nil;
  
  int32_t version = [decoder decodeInt32ForKey: @"version"];
  
  if (version >= 5)
  {
    name = [[decoder decodeObjectForKey: @"name"] copy];
    hostname = [[decoder decodeObjectForKey: @"hostname"] copy];
  }
  else
  {
    name = [[decoder decodeObjectForKey: @"worldName"] copy];
    hostname = [[decoder decodeObjectForKey: @"worldHostname"] copy];
  }
  
  if (version >= 6)
    port = [[NSNumber alloc] initWithInt: [decoder decodeIntForKey: @"port"]];
  else if (version == 5)
    port = [[decoder decodeObjectForKey: @"port"] copy];
  else
    port = [[decoder decodeObjectForKey: @"worldPort"] copy];
  
  players = [[decoder decodeObjectForKey: @"players"] mutableCopy];
  
  if (version >= 5)
    url = [[decoder decodeObjectForKey: @"URL"] copy];
  else if (version >= 1)
    url = [[decoder decodeObjectForKey: @"worldURL"] copy];
  else
    url = [@"" copy];
  
  if (version >= 6)
    isExpanded = [decoder decodeBoolForKey: @"isExpanded"];
  else
    isExpanded = YES;
  
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
                                             players: self.players];
}

@end

#pragma mark -

@implementation MUWorld (Private)

- (void) postWorldsDidChangeNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUWorldsDidChangeNotification
                                                      object: self];
}

@end
