//
// J3Socket.m
//
// Copyright (c) 2007 3James Software.
//

#import "J3Socket.h"

#import <sys/ioctl.h>
#import <sys/socket.h>
#import <errno.h>
#import <netdb.h>
#import <poll.h>
#import <stdarg.h>
#import <unistd.h>

#pragma mark -
#pragma mark C Function Prototypes

static inline ssize_t full_write (int file_descriptor, const void *bytes, size_t length);
static inline ssize_t safe_read (int file_descriptor, void *bytes, size_t length);
static inline ssize_t safe_write (int file_descriptor, const void *bytes, size_t length);

#pragma mark -

@interface J3Socket (Private)

- (void) checkRemoteConnection;
- (void) connectSocket;
- (void) createSocket;
- (void) initializeDescriptorSet: (fd_set *) set;
- (void) performPostConnectNegotiation;
- (void) resolveHostname;
- (void) setStatusConnected;
- (void) setStatusConnecting;
- (void) setStatusClosedByClient;
- (void) setStatusClosedByServer;
- (void) setStatusClosedWithError: (NSString *) error;

@end

#pragma mark -

@implementation J3SocketException

+ (void) socketError: (NSString *) errorMessage
{
  @throw [J3SocketException exceptionWithName: @"" reason: errorMessage userInfo: nil];
}

+ (void) socketErrorWithFormat: (NSString *) format, ...
{
  va_list args;
  va_start (args, format);
  
  NSString *message = [[[NSString alloc] initWithFormat: format arguments: args] autorelease];
  
  va_end (args);
  
  [self socketError: message];
}

+ (void) socketErrorWithErrnoForFunction: (NSString *) functionName;
{
  [J3SocketException socketError: [NSString stringWithFormat: @"%@: %s", functionName, strerror (errno)]];
}

@end

#pragma mark -

@implementation J3Socket

+ (id) socketWithHostname: (NSString *) hostname port: (int) port
{
  return [[[self alloc] initWithHostname: hostname port: port] autorelease];
}

- (id) initWithHostname: (NSString *) newHostname port: (int) newPort
{
  if (![super init])
    return nil;
  
  [self at: &hostname put: [newHostname retain]];
  socketfd = -1;
  port = newPort;
  status = J3SocketStatusNotConnected;
  server = NULL;
  
  return self;
}

- (void) dealloc
{
  delegate = nil;
  [hostname release];
  
  if (server)
    free (server);
  
  [super dealloc];
}

- (void) close
{
  if (![self isConnected])
    return;
  
  errno = 0;
  
  // Note that looping on EINTR is specifically wrong for close(2), since the
  // underlying fd will be closed either way; EINTR here tends to indicate that
  // a final flush was interrupted and we may have lost data.
  /* int result = */ close (socketfd);
  
  socketfd = -1;
  [self setStatusClosedByClient];
  
  // TODO: handle result == -1 in some way. We could throw an exception, return
  // it up from here, but it should be noted and handled.
}

- (BOOL) isClosed
{
  return status == J3SocketStatusClosed;
}

- (BOOL) isConnected
{
  return status == J3SocketStatusConnected;
}

- (BOOL) isConnecting
{
  return status == J3SocketStatusConnecting;
}

- (void) open
{
  if ([self isConnected] || [self isConnecting])
    return;
  
  @try
  {
    [self setStatusConnecting];
    [self resolveHostname];
    [self createSocket];
    [self connectSocket];
    [self performPostConnectNegotiation];
    [self setStatusConnected];    
  }
  @catch (J3SocketException *socketException)
  {
    [self setStatusClosedWithError: [socketException reason]];
  }
}

- (void) poll
{
  hasDataAvailable = NO;
  
  fd_set read_set;
  struct timeval tval;
  
  memset (&tval, 0, sizeof (struct timeval));
  tval.tv_usec = 100;
  
  [self initializeDescriptorSet: &read_set];
  errno = 0;
  
  int result = select (socketfd + 1, &read_set, NULL, NULL, &tval);  
  
  if (result < 0)
    [J3SocketException socketErrorWithErrnoForFunction: @"select"];
  
  if (FD_ISSET (socketfd, &read_set))
  {
    hasDataAvailable = YES;
    [self checkRemoteConnection];
  }
}

- (void) setDelegate: (NSObject <J3SocketDelegate> *) object
{
  delegate = object;
}

- (J3SocketStatus) status
{
  return status;
}

#pragma mark -
#pragma mark J3ByteSource protocol

- (BOOL) hasDataAvailable
{
  return hasDataAvailable;
}

- (NSData *) readUpToLength: (size_t) length
{
  uint8_t *bytes = malloc (length);
  if (!bytes)
  {
    @throw [NSException exceptionWithName: NSMallocException reason: @"Could not allocate socket read buffer" userInfo: nil];
  }

  errno = 0;
  
  ssize_t bytesRead = safe_read (socketfd, bytes, length);
    
  if (bytesRead < 0)
  {
    free (bytes);
    
    // TODO: is this correct?
    if (!([self isConnected] || [self isConnecting]))
      return nil;
    
    if (errno == EBADF || errno == EPIPE)
      [self setStatusClosedByServer];
    
    [J3SocketException socketErrorWithErrnoForFunction: @"read"];
  }
  
  return [NSData dataWithBytesNoCopy: bytes length: bytesRead];
}

#pragma mark -
#pragma mark J3ByteDestination protocol

- (ssize_t) write: (NSData *) data
{
  errno = 0;
  
  ssize_t result = full_write (socketfd, [data bytes], (size_t) [data length]);
  
  if (result < 0)
  {
    // TODO: is this correct?
    if (!([self isConnected] || [self isConnecting]))
      return nil;
    
    if (errno == EBADF || errno == EPIPE)
      [self setStatusClosedByServer];
    
    [J3SocketException socketErrorWithErrnoForFunction: @"write"];
  }
  
  return result;
}

@end

#pragma mark -

@implementation J3Socket (Private)

- (void) checkRemoteConnection
{
  char *nread;
  int result = ioctl (socketfd, FIONREAD, &nread);
  
  if (result < 0)
  {
    hasDataAvailable = NO;
    [J3SocketException socketErrorWithErrnoForFunction: @"ioctl"];
  }
  if (!nread)
  {
    close (socketfd);
    hasDataAvailable = NO;
    [self setStatusClosedByServer];
  }
}

- (void) connectSocket
{
  errno = 0;
  
  struct sockaddr_in server_address;
  
  server_address.sin_family = AF_INET;
  server_address.sin_port = htons (port);
  memcpy (&server_address.sin_addr.s_addr, server->h_addr, server->h_length);   
  
  if (connect (socketfd, (struct sockaddr *) &server_address, sizeof (struct sockaddr)) == -1)
  {
    if (errno != EINTR)
    {
      [J3SocketException socketErrorWithErrnoForFunction: @"connect"];
      return;
    }
    
    struct pollfd socket_status;
    socket_status.fd = socketfd;
    socket_status.events = POLLOUT;
    
    while (poll (&socket_status, 1, -1) == -1)
    {
      if (errno != EINTR)
      {
        [J3SocketException socketErrorWithErrnoForFunction: @"poll"];
        return;
      }
    }
    
    int connect_error;
    socklen_t connect_error_length = sizeof (connect_error);
    
    if (getsockopt (socketfd, SOL_SOCKET, SO_ERROR, &connect_error, &connect_error_length) == -1)
    {
      [J3SocketException socketErrorWithErrnoForFunction: @"getsockopt"];
      return;
    }
    
    if (connect_error != 0)
    {
      [J3SocketException socketError: [NSString stringWithFormat: @"delayed connect: %s", strerror (connect_error)]];
      return;
    }
    
    // If we reach this point, the socket has successfully connected. =p
  }
}

- (void) createSocket
{  
  errno = 0;
  socketfd = socket (AF_INET, SOCK_STREAM, 0);
  if (socketfd == -1)
    [J3SocketException socketErrorWithErrnoForFunction: @"socket"];
}

- (void) initializeDescriptorSet: (fd_set *) set
{
  FD_ZERO (set);
  FD_SET (socketfd, set);
}

- (void) performPostConnectNegotiation
{
  // Override in subclass to do something after connecting but before changing status
}

- (void) resolveHostname
{
  h_errno = 0;
  
  if (server)
    return;
  
  server = malloc (sizeof (struct hostent));
  if (!server)
    @throw [NSException exceptionWithName: NSMallocException reason: @"Could not allocate struct hostent for socket" userInfo: nil];
  
  @synchronized ([self class])
  {
    struct hostent *hostent = gethostbyname ([hostname cString]);
    
    if (hostent)
      memcpy (server, hostent, sizeof (struct hostent));
    else
    {
      free (server);
      server = NULL;
      const char *error = hstrerror (h_errno);
      [J3SocketException socketErrorWithFormat: @"%s", error];
    }
  }
}

- (void) setStatusConnected
{
  status = J3SocketStatusConnected;
  if (delegate && [delegate respondsToSelector: @selector (socketIsConnected:)])
    [delegate socketIsConnected: self];
}

- (void) setStatusConnecting
{
  status = J3SocketStatusConnecting;
  if (delegate && [delegate respondsToSelector: @selector (socketIsConnecting:)])
    [delegate socketIsConnecting: self];
}

- (void) setStatusClosedByClient
{
  status = J3SocketStatusClosed;
  if (delegate && [delegate respondsToSelector: @selector (socketWasClosedByClient:)])
    [delegate socketWasClosedByClient: self];
}

- (void) setStatusClosedByServer
{
  status = J3SocketStatusClosed;
  if (delegate && [delegate respondsToSelector: @selector (socketWasClosedByServer:)])
    [delegate socketWasClosedByServer: self];
}

- (void) setStatusClosedWithError: (NSString *) error
{
  status = J3SocketStatusClosed;
  if (delegate && [delegate respondsToSelector: @selector (socketWasClosed:withError:)])
    [delegate socketWasClosed: self withError: error];
}

@end

#pragma mark -
#pragma mark C Functions

static inline ssize_t
full_write (int file_descriptor, const void *bytes, size_t length)
{
  ssize_t bytes_written;
  ssize_t total_bytes_written = 0;
  
  while (length > 0)
  {
    bytes_written = safe_write (file_descriptor, bytes, length);
    if (bytes_written < 0)
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
  while (bytes_read < 0 && errno == EINTR);
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
  while (bytes_written < 0 && errno == EINTR);  
  return bytes_written;  
}

