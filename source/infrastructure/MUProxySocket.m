//
// MUProxySocket.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUProxySocket.h"
#import "MUProxySettings.h"
#import "MUSOCKS5Constants.h"
#import "MUSOCKS5Authentication.h"
#import "MUSOCKS5MethodSelection.h"
#import "MUSOCKS5Request.h"
#import "MUWriteBuffer.h"

@interface MUProxySocket (Private)

- (void) makeRequest;
- (void) performMethodSpecificNegotiation: (MUSOCKS5Method) method;
- (void) performUsernamePasswordNegotiation;
- (MUSOCKS5Method) selectMethod;

@end

#pragma mark -

@implementation MUProxySocket

+ (id) socketWithHostname: (NSString *) hostname port: (int) port proxySettings: (MUProxySettings *) settings
{
  return [[[self alloc] initWithHostname: hostname port: port proxySettings: settings] autorelease];
}

- (id) initWithHostname: (NSString *) hostnameValue port: (int) portValue proxySettings: (MUProxySettings *) settings
{
  if (!(self = [super initWithHostname: [settings hostname] port: [[settings port] intValue]]))
    return nil;
  
  realHostname = [hostnameValue copy];
  realPort = portValue;
  proxySettings = [settings retain];
  outputBuffer = [[MUWriteBuffer buffer] retain];
  [outputBuffer setByteDestination: self];
  
  return self;
}

- (void) dealloc
{
  [realHostname release];
  [proxySettings release];
  [outputBuffer release];
  [super dealloc];
}

- (void) performPostConnectNegotiation
{
  [self performMethodSpecificNegotiation: [self selectMethod]];
  [self makeRequest];
}

@end

#pragma mark -

@implementation MUProxySocket (Private)

- (void) makeRequest
{
  MUSOCKS5Request *request = [MUSOCKS5Request socksRequestWithHostname: realHostname port: realPort];

  [request appendToBuffer: outputBuffer];
  [outputBuffer flush];
  [request parseReplyFromByteSource: self];
  if ([request reply] != MUSOCKS5Success)
    [MUSocketException socketError: @"Unable to establish connection via proxy"];  
}

- (void) performMethodSpecificNegotiation: (MUSOCKS5Method) method
{
  if (method == MUSOCKS5NoAcceptableMethods)
    [MUSocketException socketError: @"No acceptable SOCKS5 methods"];
  else if (method == MUSOCKS5UsernamePassword)
    [self performUsernamePasswordNegotiation];  
}

- (void) performUsernamePasswordNegotiation
{
  MUSOCKS5Authentication *auth = [MUSOCKS5Authentication socksAuthenticationWithUsername: [proxySettings username] password: [proxySettings password]];
  
  [auth appendToBuffer: outputBuffer];
  [outputBuffer flush];
  [auth parseReplyFromSource: self];
  if (![auth authenticated])
    [MUSocketException socketError: @"Could not authenticate to proxy"];
}

- (MUSOCKS5Method) selectMethod
{
  MUSOCKS5MethodSelection *methodSelection = [MUSOCKS5MethodSelection socksMethodSelection];

  if ([proxySettings hasAuthentication])
    [methodSelection addMethod: MUSOCKS5UsernamePassword];
  [methodSelection appendToBuffer: outputBuffer];
  [outputBuffer flush];
  [methodSelection parseResponseFromByteSource: self];
  return [methodSelection method];  
}

@end
