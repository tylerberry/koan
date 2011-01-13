//
// MUCodingService.h
//
// Copyright (c) 2010 3James Software.
//

#import "MUCodingService.h"
#import "MUProfile.h"
#import "J3ProxySettings.h"

static const int32_t currentProfileVersion = 2;
static const int32_t currentPlayerVersion = 1;
static const int32_t currentProxyVersion = 2;

#pragma mark -

@implementation MUCodingService

+ (void) encodePlayer: (MUPlayer *) player withCoder: (NSCoder *) encoder
{
  [encoder encodeInt32: currentPlayerVersion forKey: @"version"];
  
  [encoder encodeObject: player.name forKey: @"name"];
  [encoder encodeObject: player.password forKey: @"password"];  
}

+ (void) decodePlayer: (MUPlayer *) player withCoder: (NSCoder *) decoder
{
  // int32_t version = [decoder decodeInt32ForKey: @"version"];
  
  player.name = [decoder decodeObjectForKey: @"name"];
  player.password = [decoder decodeObjectForKey: @"password"];
}

+ (void) encodeProfile: (MUProfile *) profile withCoder: (NSCoder *) encoder
{
  [encoder encodeInt32: currentProfileVersion forKey: @"version"];
  [encoder encodeBool: profile.autoconnect forKey: @"autoconnect"];
  [encoder encodeObject: [[profile font] fontName] forKey: @"fontName"];
  [encoder encodeFloat: [[profile font] pointSize] forKey: @"fontSize"];
  [encoder encodeObject: [NSArchiver archivedDataWithRootObject: [profile textColor]] forKey: @"textColor"];
  [encoder encodeObject: [NSArchiver archivedDataWithRootObject: [profile backgroundColor]] forKey: @"backgroundColor"];
  [encoder encodeObject: [NSArchiver archivedDataWithRootObject: [profile linkColor]] forKey: @"linkColor"];
  [encoder encodeObject: [NSArchiver archivedDataWithRootObject: [profile visitedLinkColor]] forKey: @"visitedLinkColor"];
}

+ (void) decodeProfile: (MUProfile *) profile withCoder: (NSCoder *) decoder
{
  int32_t version = [decoder decodeInt32ForKey: @"version"];
  
  profile.autoconnect = [decoder decodeBoolForKey: @"autoconnect"];
  
  if (version >= 2)
  {
  	[profile setFont: [NSFont fontWithName: [decoder decodeObjectForKey: @"fontName"]
  																	 size: [decoder decodeFloatForKey: @"fontSize"]]];
  	[profile setTextColor: [NSUnarchiver unarchiveObjectWithData: [decoder decodeObjectForKey: @"textColor"]]];
  	[profile setBackgroundColor: [NSUnarchiver unarchiveObjectWithData: [decoder decodeObjectForKey: @"backgroundColor"]]];
  	[profile setLinkColor: [NSUnarchiver unarchiveObjectWithData: [decoder decodeObjectForKey: @"linkColor"]]];
  	[profile setVisitedLinkColor: [NSUnarchiver unarchiveObjectWithData: [decoder decodeObjectForKey: @"visitedLinkColor"]]];
  }
}

+ (void) encodeWorld: (MUWorld *) world withCoder: (NSCoder *) encoder
{
  return;
}

+ (void) decodeWorld: (MUWorld *) world withCoder: (NSCoder *) decoder
{
  return;
}

+ (void) encodeProxySettings: (J3ProxySettings *) settings withCoder: (NSCoder *) encoder;
{
  [encoder encodeInt32: currentProxyVersion forKey: @"version"];
  
  [encoder encodeObject: [settings hostname] forKey: @"hostname"];
  [encoder encodeObject: [settings port] forKey: @"port"];  
  [encoder encodeObject: [settings username] forKey: @"username"];
  [encoder encodeObject: [settings password] forKey: @"password"];  
}

+ (void) decodeProxySettings: (J3ProxySettings *) settings withCoder: (NSCoder *) decoder;
{
  int32_t version = [decoder decodeInt32ForKey: @"version"];
  
  [settings setHostname: [decoder decodeObjectForKey: @"hostname"]];
  [settings setPort: [decoder decodeObjectForKey: @"port"]];
  if (version >= 2)
  {
    [settings setUsername: [decoder decodeObjectForKey: @"username"]];
    [settings setPassword: [decoder decodeObjectForKey: @"password"]];
  }
  else
  {
    [settings setUsername: @""];
    [settings setPassword: @""];    
  }
}

@end
