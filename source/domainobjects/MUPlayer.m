//
// MUPlayer.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUPlayer.h"

#import <Security/Security.h>

static const int32_t currentPlayerVersion = 4;

@implementation MUPlayer

@dynamic loginString, password, windowTitle, world;

+ (MUPlayer *) playerWithName: (NSString *) newName
{
  return [[self alloc] initWithName: newName];
}

- (id) initWithName: (NSString *) newName
{
  if (!(self = [super initWithName: newName children: nil]))
    return nil;
  
  return self;
}

- (id) init
{
  return [self initWithName: @"New player"];
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

- (NSString *) password
{
  void *passwordBytes = NULL;
  UInt32 passwordLength = 0;
  SecKeychainItemRef itemRef;
  
  const char *hostnameUTF8String = [self.world.hostname UTF8String];
  const char *playerUTF8String = [self.name UTF8String];
  
  OSStatus status = SecKeychainFindInternetPassword (NULL,
                                                     (UInt32) strlen (hostnameUTF8String),
                                                     hostnameUTF8String,
                                                     0,
                                                     NULL,
                                                     (UInt32) strlen (playerUTF8String),
                                                     playerUTF8String,
                                                     0,
                                                     NULL,
                                                     self.world.port.unsignedShortValue,
                                                     kSecProtocolTypeTelnet,
                                                     kSecAuthenticationTypeDefault,
                                                     &passwordLength,
                                                     &passwordBytes,
                                                     &itemRef);
  
  if (status == errSecSuccess)
  {
    NSString *password = [[NSString alloc] initWithBytes: passwordBytes
                                                  length: passwordLength
                                                encoding: NSUTF8StringEncoding];
    
    SecKeychainItemFreeContent (NULL, passwordBytes);
    
    return password;
  }
  else if (status == errSecItemNotFound)
  {
    if (passwordBytes)
      SecKeychainItemFreeContent (NULL, passwordBytes);
    
    return nil;
  }
  else
	{
    NSString *errorString = (__bridge_transfer NSString *) SecCopyErrorMessageString (status, NULL);
    
    NSLog (@"Keychain error %u: %@", status, errorString);
    
    if (passwordBytes)
      SecKeychainItemFreeContent (NULL, passwordBytes);
    
    return nil;
	}
}

- (void) setPassword: (NSString *) password
{
  SecKeychainItemRef itemRef;
  
  const char *hostnameUTF8String = [self.world.hostname UTF8String];
  const char *playerUTF8String = [self.name UTF8String];
  
  OSStatus status = SecKeychainFindInternetPassword (NULL,
                                                     (UInt32) strlen (hostnameUTF8String),
                                                     hostnameUTF8String,
                                                     0,
                                                     NULL,
                                                     (UInt32) strlen (playerUTF8String),
                                                     playerUTF8String,
                                                     0,
                                                     NULL,
                                                     self.world.port.unsignedShortValue,
                                                     kSecProtocolTypeTelnet,
                                                     kSecAuthenticationTypeDefault,
                                                     0,
                                                     NULL,
                                                     &itemRef);
  
  if (status == errSecSuccess)
  {
    if (!password || password.length == 0)
    {
      SecKeychainItemDelete (itemRef);
    }
    else
    {
      const char *passwordUTF8String = [password UTF8String];
      
      SecKeychainItemModifyAttributesAndData (itemRef,
                                              NULL,
                                              (UInt32) strlen (passwordUTF8String),
                                              passwordUTF8String);
    }
  }
  else if (status == errSecItemNotFound)
  {
    if (!password || password.length == 0)
      return;
    
    const char *passwordUTF8String = [password UTF8String];
    
    SecKeychainAddInternetPassword (NULL,
                                    (UInt32) strlen (hostnameUTF8String),
                                    hostnameUTF8String,
                                    0,
                                    NULL,
                                    (UInt32) strlen (playerUTF8String),
                                    playerUTF8String,
                                    0,
                                    NULL,
                                    self.world.port.unsignedShortValue,
                                    kSecProtocolTypeTelnet,
                                    kSecAuthenticationTypeDefault,
                                    (UInt32) strlen (passwordUTF8String),
                                    passwordUTF8String,
                                    NULL);
  }
  else
  {
    NSString *errorString = (__bridge_transfer NSString *) SecCopyErrorMessageString (status, NULL);
    
    NSLog (@"Keychain error %u: %@", status, errorString);
  }
}

- (NSString *) windowTitle
{
  // FIXME: This is not the right way to get the window title.
  return [NSString stringWithFormat: @"%@ @ %@", self.name, self.parent.name];
}

- (MUWorld *) world
{
  return (MUWorld *) self.parent;
}

#pragma mark - NSCoding protocol

- (void) encodeWithCoder: (NSCoder *) encoder
{
  [super encodeWithCoder: encoder];
  
  [encoder encodeInt32: currentPlayerVersion forKey: @"playerVersion"];
  
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
  MUPlayer *copy = [[MUPlayer allocWithZone: zone] initWithName: self.name];
  
  copy.fugueEditPrefix = self.fugueEditPrefix;
  
  return copy;
}

@end
