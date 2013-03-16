//
// MUSocket.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUSocket.h"
#import "MUSocketSubclass.h"
#import "MUAbstractConnectionSubclass.h"

#include <errno.h>
#include <netdb.h>
#include <poll.h>
#include <stdarg.h>
#include <sys/event.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <unistd.h>

#define MUSOCKET_KQUEUE 1

NSString *MUSocketDidConnectNotification = @"MUSocketDidConnectNotification";
NSString *MUSocketIsConnectingNotification = @"MUSocketIsConnectingNotification";
NSString *MUSocketWasClosedByClientNotification = @"MUSocketWasClosedByClientNotification";
NSString *MUSocketWasClosedByServerNotification = @"MUSocketWasClosedByServerNotification";
NSString *MUSocketWasClosedWithErrorNotification = @"MUSocketWasClosedWithErrorNotification";
NSString *MUSocketErrorKey = @"MUSocketErrorKey";

#pragma mark - C Function Prototypes

static inline ssize_t full_write (int file_descriptor, const void *bytes, size_t length);
static inline ssize_t safe_read (int file_descriptor, void *bytes, size_t length);
static inline ssize_t safe_write (int file_descriptor, const void *bytes, size_t length);

#pragma mark -

@implementation MUSocketException

+ (void) socketError: (NSString *) errorMessage
{
  @throw [MUSocketException exceptionWithName: @"" reason: errorMessage userInfo: nil];
}

+ (void) socketErrorWithFormat: (NSString *) format, ...
{
  va_list args;
  va_start (args, format);
  
  NSString *message = [[NSString alloc] initWithFormat: format arguments: args];
  
  va_end (args);
  
  [self socketError: message];
}

+ (void) socketErrorWithErrnoForFunction: (NSString *) functionName
{
  [MUSocketException socketError: [NSString stringWithFormat: @"%@: %s", functionName, strerror (errno)]];
}

@end

#pragma mark -

@interface MUSocket ()
{
  NSString *_hostname;
  uint16_t _port;
  
  NSNumber *_availableBytes;
  NSMutableData *_dataToWrite;
  BOOL _hasError;
  
  int _socketfd;
  struct hostent *_serverHostent;

#ifdef MUSOCKET_KQUEUE
  int _kqueue;
#endif
}

- (void) _close;
- (void) _connectSocket;
- (void) _createSocket;
- (void) _open;
- (void) _read;
- (void) _registerObjectForNotifications: (id) object;
- (void) _resolveHostname;
- (void) _runThread: (id) object;
- (void) _unregisterObjectForNotifications: (id) object;
- (void) _write;

#ifdef MUSOCKET_KQUEUE
- (void) _initializeKernelQueue;
#endif

@end

#pragma mark -

@implementation MUSocket

@synthesize delegate = _delegate;

+ (id) socketWithHostname: (NSString *) hostname port: (uint16_t) port
{
  return [[self alloc] initWithHostname: hostname port: port];
}

- (id) initWithHostname: (NSString *) newHostname port: (uint16_t) newPort
{
  if (!(self = [super init]))
    return nil;
  
  _availableBytes = [NSNumber numberWithUnsignedInteger: 0];
  _hostname = [newHostname copy];
  _socketfd = -1;
  _port = newPort;
  _serverHostent = NULL;
  _dataToWrite = [[NSMutableData alloc] initWithCapacity: 2048];
  
  return self;
}

- (void) dealloc
{
  [self close];
  
  [self _unregisterObjectForNotifications: _delegate];
  _delegate = nil;
 
  if (_serverHostent)
    free (_serverHostent);
}

- (void) setDelegate: (NSObject <MUSocketDelegate> *) newDelegate
{
  if (_delegate == newDelegate)
    return;
  
  [self _unregisterObjectForNotifications: _delegate];
  [self _registerObjectForNotifications: newDelegate];
  
  _delegate = newDelegate;
}

- (void) close
{
  [self _close];
}

- (void) open
{
  [NSThread detachNewThreadSelector: @selector (_runThread:) toTarget: self withObject: nil];
}

- (void) performPostConnectNegotiation
{
  // Override in subclass to do something after connecting but before changing status.
  return;
}

#pragma mark - MUAbstractConnection overrides

- (void) setStatusConnected
{
  [super setStatusConnected];
  [[NSNotificationCenter defaultCenter] postNotificationName: MUSocketDidConnectNotification
                                                      object: self];
}

- (void) setStatusConnecting
{
  [super setStatusConnecting];
  [[NSNotificationCenter defaultCenter] postNotificationName: MUSocketIsConnectingNotification
                                                      object: self];
}

- (void) setStatusClosedByClient
{
  [super setStatusClosedByClient];
  [[NSNotificationCenter defaultCenter] postNotificationName: MUSocketWasClosedByClientNotification
                                                      object: self];
}

- (void) setStatusClosedByServer
{
  [super setStatusClosedByServer];
  [[NSNotificationCenter defaultCenter] postNotificationName: MUSocketWasClosedByServerNotification
                                                      object: self];
}

- (void) setStatusClosedWithError: (NSError *) error
{
  [super setStatusClosedWithError: error];
  [[NSNotificationCenter defaultCenter] postNotificationName: MUSocketWasClosedWithErrorNotification
                                                      object: self
                                                    userInfo: @{MUSocketErrorKey: error}];
}

#pragma mark - MUByteSource protocol

- (NSUInteger) availableBytes
{
  return _availableBytes.unsignedIntegerValue;
}

- (BOOL) hasDataAvailable
{
  return _availableBytes.unsignedIntegerValue > 0;
}

- (void) poll
{
  [self _write];
  [self _read];
}

- (NSData *) readExactlyLength: (size_t) length
{
  while ((self.isConnected || self.isConnecting)
         && _availableBytes.unsignedIntegerValue < length)
    [self poll];
  
  return [self readUpToLength: length];
}

- (NSData *) readUpToLength: (size_t) length
{
  uint8_t *bytes = malloc (length);
  if (!bytes)
  {
    @throw [NSException exceptionWithName: NSMallocException
                                   reason: @"Could not allocate socket read buffer"
                                 userInfo: nil];
  }

  errno = 0;
  
  ssize_t bytesRead = safe_read (_socketfd, bytes, length);
    
  if (bytesRead == -1)
  {
    free (bytes);
    
    // TODO: Is this correct?
    if (!(self.isConnected || self.isConnecting))
      return nil;
    
    if (errno == EBADF || errno == EPIPE)
      [self performSelectorOnMainThread: @selector (setStatusClosedByServer)
                             withObject: nil
                          waitUntilDone: YES];
    
    [MUSocketException socketErrorWithErrnoForFunction: @"read"];
  }
  
  @synchronized (_availableBytes)
  {
    _availableBytes = [NSNumber numberWithUnsignedInteger: _availableBytes.unsignedIntegerValue - bytesRead];
  }
  
  return [NSData dataWithBytesNoCopy: bytes length: bytesRead];
}

#pragma mark - MUByteDestination protocol

- (void) write: (NSData *) data
{
  @synchronized (_dataToWrite)
  {
    [_dataToWrite appendData: data];
  }
}

#pragma mark - Private methods

- (void) _connectSocket
{
  errno = 0;
  _availableBytes = 0;
  
  struct sockaddr_in server_address;
  
  server_address.sin_family = AF_INET;
  server_address.sin_port = htons (_port);
  memcpy (&server_address.sin_addr.s_addr, _serverHostent->h_addr, _serverHostent->h_length);   
  
  if (connect (_socketfd, (struct sockaddr *) &server_address, sizeof (struct sockaddr)) == -1)
  {
    if (errno != EINTR)
    {
      [MUSocketException socketErrorWithErrnoForFunction: @"connect"];
      return;
    }
    
    struct pollfd socket_status;
    socket_status.fd = _socketfd;
    socket_status.events = POLLOUT;
    
    while (poll (&socket_status, 1, -1) == -1)
    {
      if (errno != EINTR)
      {
        [MUSocketException socketErrorWithErrnoForFunction: @"poll"];
        return;
      }
    }
    
    int connect_error;
    socklen_t connect_error_length = sizeof (connect_error);
    
    if (getsockopt (_socketfd, SOL_SOCKET, SO_ERROR, &connect_error, &connect_error_length) == -1)
    {
      [MUSocketException socketErrorWithErrnoForFunction: @"getsockopt"];
      return;
    }
    
    if (connect_error != 0)
    {
      [MUSocketException socketError: [NSString stringWithFormat: @"delayed connect: %s", strerror (connect_error)]];
      return;
    }
    
    // If we reach this point, the socket has successfully connected. =p
  }
  
#ifdef MUSOCKET_KQUEUE
  [self _initializeKernelQueue];
#endif
}

- (void) _createSocket
{  
  errno = 0;
  _socketfd = socket (AF_INET, SOCK_STREAM, 0);
  if (_socketfd == -1)
  {
    [MUSocketException socketErrorWithErrnoForFunction: @"socket"];
    return;
  }
  
  int trueval = 1;
  if (setsockopt (_socketfd, SOL_SOCKET, SO_KEEPALIVE, &trueval, sizeof (int)) == -1)
  {
    [MUSocketException socketErrorWithErrnoForFunction: @"setsockopt (SO_KEEPALIVE)"];
    return;   
  }
}

#ifdef MUSOCKET_KQUEUE
- (void) _initializeKernelQueue
{
  errno = 0;
  _kqueue = kqueue ();
  if (_kqueue == -1)
    [MUSocketException socketErrorWithErrnoForFunction: @"kqueue"];
  
  struct kevent socket_event;
  
  EV_SET (&socket_event, _socketfd, EVFILT_READ, EV_ADD, 0, 0, 0);
  
  int result;
  do
  {
    result = kevent (_kqueue, &socket_event, 1, NULL, 0, NULL);
  }
  while (result == -1 && errno == EINTR);
  
  if (result == -1)
    [MUSocketException socketErrorWithErrnoForFunction: @"kevent"];
}
#endif

- (void) _close
{
  if (!(self.isConnected || self.isConnecting))
    return;
  
  errno = 0;
  
  // Note that looping on EINTR is specifically wrong for close(2), since the
  // underlying fd will be closed either way; EINTR here tends to indicate that
  // a final flush was interrupted and we may have lost data.
  /* int result = */ close (_socketfd);
  _socketfd = -1;
  [self performSelectorOnMainThread: @selector (setStatusClosedByClient) withObject: nil waitUntilDone: YES];
  
  /* int result = */ close (_kqueue);
  
  // TODO: Handle result == -1 in some way. We could throw an exception, return
  // it up from here, but it should be noted and handled.
}  

- (void) _open
{
  if (self.isConnected || self.isConnecting)
    return;
  
  @try
  {
    [self performSelectorOnMainThread: @selector (setStatusConnecting) withObject: nil waitUntilDone: YES];
    [self _resolveHostname];
    [self _createSocket];
    [self _connectSocket];
    [self performPostConnectNegotiation];
    [self performSelectorOnMainThread: @selector (setStatusConnected) withObject: nil waitUntilDone: YES];
  }
  @catch (MUSocketException *socketException)
  {
    [self performSelectorOnMainThread: @selector (setStatusClosedWithError:)
                           withObject: socketException
                        waitUntilDone: YES];
  }
}

- (void) _read
{
#ifdef MUSOCKET_KQUEUE
  struct timespec timeout = {0, 0};
  struct kevent triggered_event;
  errno = 0;
  
  int result;
  
  do
  {
    result = kevent (_kqueue, NULL, 0, &triggered_event, 1, &timeout);
  }
  while (result == -1 && errno == EINTR);
  
  if (result == -1)
    [MUSocketException socketErrorWithErrnoForFunction: @"kevent"];
  
  if (result == 0)
    return;
  
  if ((int) triggered_event.ident == _socketfd)
  {
    if (triggered_event.flags & EV_EOF)
    {
      [self performSelectorOnMainThread: @selector (setStatusClosedByServer) withObject: nil waitUntilDone: YES];
      return;
    }
  
    if (triggered_event.data > 0)
    {
      @synchronized (_availableBytes)
      {
        NSUInteger newTotal = _availableBytes.unsignedIntegerValue + triggered_event.data;
        
        _availableBytes = [NSNumber numberWithUnsignedInteger: newTotal];
      }
    }
  }
#else
  
#endif
}

- (void) _write
{
  @synchronized (_dataToWrite)
  {
    if (_dataToWrite.length == 0)
      return;
    
    errno = 0;
    ssize_t bytes_written = full_write (_socketfd, _dataToWrite.bytes, (size_t) _dataToWrite.length);
    
    if (bytes_written == -1)
    {
      // TODO: Is this correct?
      if (!(self.isConnected || self.isConnecting))
        return;
      
      if (errno == EBADF || errno == EPIPE)
        [self performSelectorOnMainThread: @selector (setStatusClosedByServer) withObject: nil waitUntilDone: YES];
      
      [MUSocketException socketErrorWithErrnoForFunction: @"write"];
    }
    
    [_dataToWrite setData: [NSData data]];
  }
}

- (void) _registerObjectForNotifications: (id) object
{
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  
  [notificationCenter addObserver: object
                         selector: @selector (socketDidConnect:)
                             name: MUSocketDidConnectNotification
                           object: self];
  [notificationCenter addObserver: object
                         selector: @selector (socketIsConnecting:)
                             name: MUSocketIsConnectingNotification
                           object: self];
  [notificationCenter addObserver: object
                         selector: @selector (socketWasClosedByClient:)
                             name: MUSocketWasClosedByClientNotification
                           object: self];
  [notificationCenter addObserver: object
                         selector: @selector (socketWasClosedByServer:)
                             name: MUSocketWasClosedByServerNotification
                           object: self];
  [notificationCenter addObserver: object
                         selector: @selector (socketWasClosedWithError:)
                             name: MUSocketWasClosedWithErrorNotification
                           object: self];
}

- (void) _resolveHostname
{
  if (_serverHostent)
    return;
  
  _serverHostent = malloc (sizeof (struct hostent));
  if (!_serverHostent)
    @throw [NSException exceptionWithName: NSMallocException reason: @"Could not allocate struct hostent for socket" userInfo: nil];
  
  @synchronized ([self class])
  {
    h_errno = 0;
    
    struct hostent *hostent = gethostbyname ([_hostname cStringUsingEncoding: NSASCIIStringEncoding]);
    
    if (hostent)
      memcpy (_serverHostent, hostent, sizeof (struct hostent));
    else
    {
      free (_serverHostent);
      _serverHostent = NULL;
      [MUSocketException socketErrorWithFormat: @"%s", hstrerror (h_errno)];
    }
  }
}

- (void) _runThread: (id) object
{
  @autoreleasepool
  {
    [self _open];
  }
}

- (void) _unregisterObjectForNotifications: (id) object
{
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  
  [notificationCenter removeObserver: object name: MUSocketDidConnectNotification object: self];
  [notificationCenter removeObserver: object name: MUSocketIsConnectingNotification object: self];
  [notificationCenter removeObserver: object name: MUSocketWasClosedByClientNotification object: self];
  [notificationCenter removeObserver: object name: MUSocketWasClosedByServerNotification object: self];
  [notificationCenter removeObserver: object name: MUSocketWasClosedWithErrorNotification object: self];
}

@end

#pragma mark - C Functions

static inline ssize_t
full_write (int file_descriptor, const void *bytes, size_t length)
{
  ssize_t bytes_written;
  ssize_t total_bytes_written = 0;
  
  while (length > 0)
  {
    bytes_written = safe_write (file_descriptor, bytes, length);
    if (bytes_written == -1)
      return bytes_written;
    total_bytes_written += bytes_written;
    bytes = (const uint8_t *) bytes + bytes_written;
    length -= bytes_written;
  }
  
  return total_bytes_written;
}

static inline ssize_t
safe_read (int file_descriptor, void *bytes, size_t length)
{
  ssize_t bytes_read;
  do
  {
    bytes_read = read (file_descriptor, bytes, length);
  }
  while (bytes_read == -1 && errno == EINTR);
  return bytes_read;
}

static inline ssize_t
safe_write (int file_descriptor, const void *bytes, size_t length)
{
  ssize_t bytes_written;
  do
  {
    bytes_written = write (file_descriptor, bytes, length);
  }
  while (bytes_written == -1 && errno == EINTR);  
  return bytes_written;  
}
