//
// MUConnectionWindowControllerRegistry.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUConnectionWindowControllerRegistry.h"

@interface MUConnectionWindowControllerRegistry ()
{
  NSMutableDictionary *_controllersKeyedByProfileUniqueIdentifier;
}

- (void) _connectionDidClose: (NSNotification *) notification;
- (void) _donnectionWillOpen: (NSNotification *) notification;
- (void) connectionWindowControllerWillClose: (NSNotification *) notification;
- (void) _registerForNotifications;
- (void) _unregisterForNotifications;

@end

#pragma mark -

@implementation MUConnectionWindowControllerRegistry

@dynamic count;

+ (MUConnectionWindowControllerRegistry *) defaultRegistry
{
  static MUConnectionWindowControllerRegistry *_defaultRegistry = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ _defaultRegistry = [[MUConnectionWindowControllerRegistry alloc] init]; });
  
  return _defaultRegistry;
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  _controllers = [[NSMutableSet alloc] init];
  _controllersKeyedByProfileUniqueIdentifier = [[NSMutableDictionary alloc] init];
  _connectedCount = 0;
  
  [self _registerForNotifications];
  
  return self;
}

- (void) dealloc
{
  [self _unregisterForNotifications];
}

- (MUConnectionWindowController *) controllerForProfile: (MUProfile *) profile
{
  if (_controllersKeyedByProfileUniqueIdentifier[profile.uniqueIdentifier])
    return _controllersKeyedByProfileUniqueIdentifier[profile.uniqueIdentifier];
  else
  {
    MUConnectionWindowController *controller = [[MUConnectionWindowController alloc] initWithProfile: profile];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector (_connectionWindowControllerWillClose:)
                                                 name: MUConnectionWindowControllerWillCloseNotification
                                               object: controller];
    
    _controllersKeyedByProfileUniqueIdentifier[profile.uniqueIdentifier] = controller;
    [_controllers addObject: controller];
    
    return controller;
  }
}

#pragma mark - Property method implementations

- (NSUInteger) count
{
  return _controllers.count;
}

#pragma mark - Private methods

- (void) _connectionWindowControllerWillClose: (NSNotification *) notification
{
  MUConnectionWindowController *controller = notification.object;
  
  [[NSNotificationCenter defaultCenter] removeObserver: self
                                                  name: MUConnectionWindowControllerWillCloseNotification
                                                object: controller];
  
  [_controllers removeObject: controller];
  [_controllersKeyedByProfileUniqueIdentifier removeObjectForKey: controller.profile.uniqueIdentifier];
}

- (void) _connectionDidClose: (NSNotification *) notification
{
  _connectedCount--;
}

- (void) _donnectionWillOpen: (NSNotification *) notification
{
  _connectedCount++;
}

- (void) _registerForNotifications
{
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  
  [notificationCenter addObserver: self
                         selector: @selector (_donnectionWillOpen:)
                             name: MUMUDConnectionIsConnectingNotification
                           object: nil];
  [notificationCenter addObserver: self
                         selector: @selector (_connectionDidClose:)
                             name: MUMUDConnectionWasClosedByClientNotification
                           object: nil];
  [notificationCenter addObserver: self
                         selector: @selector (_connectionDidClose:)
                             name: MUMUDConnectionWasClosedByServerNotification
                           object: nil];
  [notificationCenter addObserver: self
                         selector: @selector (_connectionDidClose:)
                             name: MUMUDConnectionWasClosedWithErrorNotification
                           object: nil];
}

- (void) _unregisterForNotifications
{
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

  
  [notificationCenter removeObserver: self
                                name: MUMUDConnectionIsConnectingNotification
                              object: nil];
  [notificationCenter removeObserver: self
                                name: MUMUDConnectionWasClosedByClientNotification
                              object: nil];
  [notificationCenter removeObserver: self
                                name: MUMUDConnectionWasClosedByServerNotification
                              object: nil];
  [notificationCenter removeObserver: self
                                name: MUMUDConnectionWasClosedWithErrorNotification
                              object: nil];
  
  for (MUConnectionWindowController *controller in self.controllers)
  {
    [notificationCenter removeObserver: self
                                  name: MUConnectionWindowControllerWillCloseNotification
                                object: controller];
  }
}

@end
