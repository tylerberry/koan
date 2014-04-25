//
// MUGrowlService.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUGrowlService.h"

@interface MUGrowlService ()

- (void) notifyWithName: (NSString *) name
                  title: (NSString *) title
            description: (NSString *) description;

@end

#pragma mark -

@implementation MUGrowlService
{
  BOOL _growlIsReady;
}

+ (MUGrowlService *) defaultGrowlService
{
  static MUGrowlService *_defaultGrowlService;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ _defaultGrowlService = [[MUGrowlService alloc] init]; });
  
  return _defaultGrowlService;
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  [GrowlApplicationBridge setGrowlDelegate: self];

  _growlIsReady = [GrowlApplicationBridge isGrowlRunning];
  
  return self;
}

+ (void) connectionOpenedForTitle: (NSString *) title
{
  [[MUGrowlService defaultGrowlService] notifyWithName: @"Connection opened"
                                                 title: title
                                           description: _(MUGConnectionOpened)];
}

+ (void) connectionClosedForTitle: (NSString *) title
{
  [[MUGrowlService defaultGrowlService] notifyWithName: @"Connection closed"
                                                 title: title
                                           description: _(MUGConnectionClosed)];
}

+ (void) connectionClosedByServerForTitle: (NSString *) title
{
  [[MUGrowlService defaultGrowlService] notifyWithName: @"Connection closed by server"
                                                 title: title
                                           description: _(MUGConnectionClosedByServer)];
}

+ (void) connectionClosedByErrorForTitle: (NSString *) title error: (NSError *) error
{
  NSString *description;
  
  if (error)
    description = [NSString stringWithFormat: _(MUGConnectionClosedByError), error.localizedDescription];
  else
    description = [NSString stringWithFormat: _(MUGConnectionClosedByError), _(MULConnectionNoErrorAvailable)];
  
  [[MUGrowlService defaultGrowlService] notifyWithName: @"Connection closed by error"
                                                 title: title
                                           description: description];
}

#pragma mark - GrowlApplicationBridge delegate

- (NSString *) applicationNameForGrowl
{
  return MUApplicationName;
}

- (void) growlIsReady
{
  _growlIsReady = YES;
}

#pragma mark - Private methods

- (void) notifyWithName: (NSString *) name
                  title: (NSString *) title
            description: (NSString *) description
{
    [GrowlApplicationBridge notifyWithTitle: title
                                description: description
                           notificationName: name
                                   iconData: nil
                                   priority: 0
                                   isSticky: NO
                               clickContext: nil];
}

@end
