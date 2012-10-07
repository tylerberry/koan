//
// MUCodingService.h
//
// Copyright (c) 2012 3James Software.
//

#import "MUCodingService.h"
#import "MUProxySettings.h"

static const int32_t currentProxyVersion = 2;

#pragma mark -

@implementation MUCodingService

+ (void) encodeProxySettings: (MUProxySettings *) settings withCoder: (NSCoder *) encoder;
{
  [encoder encodeInt32: currentProxyVersion forKey: @"version"];
  
  [encoder encodeObject: settings.hostname forKey: @"hostname"];
  [encoder encodeObject: settings.port forKey: @"port"];  
  [encoder encodeObject: settings.username forKey: @"username"];
  [encoder encodeObject: settings.password forKey: @"password"];  
}

+ (void) decodeProxySettings: (MUProxySettings *) settings withCoder: (NSCoder *) decoder;
{
  int32_t version = [decoder decodeInt32ForKey: @"version"];
  
  settings.hostname = [decoder decodeObjectForKey: @"hostname"];
  settings.port = [decoder decodeObjectForKey: @"port"];
  
  if (version >= 2)
  {
    settings.username = [decoder decodeObjectForKey: @"username"];
    settings.password = [decoder decodeObjectForKey: @"password"];
  }
  else
  {
    settings.username = @"";
    settings.password = @"";    
  }
}

@end
