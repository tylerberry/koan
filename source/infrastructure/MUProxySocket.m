//
// MUProxySocket.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUProxySocket.h"
#import "MUSocketSubclass.h"

#import "MUProxySettings.h"
#import "MUSOCKS5Constants.h"
#import "MUSOCKS5Authentication.h"
#import "MUSOCKS5MethodSelection.h"
#import "MUSOCKS5Request.h"
#import "MUWriteBuffer.h"

@interface MUProxySocket ()
{
  MUProxySettings *_proxySettings;
  NSString *_realHostname;
  uint16_t _realPort;
  MUWriteBuffer *_outputBuffer;
}

- (void) makeRequest;
- (void) performMethodSpecificNegotiation: (MUSOCKS5Method) method;
- (void) performUsernamePasswordNegotiation;
- (MUSOCKS5Method) selectMethod;

@end

#pragma mark -

@implementation MUProxySocket

+ (instancetype) socketWithHostname: (NSString *) hostname
                               port: (uint16_t) port
                      proxySettings: (MUProxySettings *) settings
{
  return [[self alloc] initWithHostname: hostname port: port proxySettings: settings];
}

- (instancetype) initWithHostname: (NSString *) hostnameValue
                             port: (uint16_t) portValue
                    proxySettings: (MUProxySettings *) settings
{
  if (!(self = [super initWithHostname: settings.hostname port: settings.port.intValue]))
    return nil;
  
  _realHostname = [hostnameValue copy];
  _realPort = portValue;
  _proxySettings = [settings copy];
  _outputBuffer = [MUWriteBuffer buffer];
  [_outputBuffer setByteDestination: self];
  
  return self;
}

- (void) performPostConnectNegotiation
{
  [self performMethodSpecificNegotiation: self.selectMethod];
  [self makeRequest];
}

#pragma mark - Private methods

- (void) makeRequest
{
  MUSOCKS5Request *request = [MUSOCKS5Request socksRequestWithHostname: _realHostname port: _realPort];

  [request appendToBuffer: _outputBuffer];
  [_outputBuffer flush];
  [request parseReplyFromByteSource: self];
  if (request.reply != MUSOCKS5Success)
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
  MUSOCKS5Authentication *auth = [MUSOCKS5Authentication socksAuthenticationWithUsername: _proxySettings.username
                                                                                password: _proxySettings.password];
  
  [auth appendToBuffer: _outputBuffer];
  [_outputBuffer flush];
  [auth parseReplyFromSource: self];
  if (!auth.authenticated)
    [MUSocketException socketError: @"Could not authenticate to proxy"];
}

- (MUSOCKS5Method) selectMethod
{
  MUSOCKS5MethodSelection *methodSelection = [MUSOCKS5MethodSelection socksMethodSelection];

  if (_proxySettings.hasAuthentication)
    [methodSelection addMethod: MUSOCKS5UsernamePassword];
  [methodSelection appendToBuffer: _outputBuffer];
  [_outputBuffer flush];
  [methodSelection parseResponseFromByteSource: self];
  return methodSelection.selectedMethod;
}

@end
