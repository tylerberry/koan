//
// MUMCCPProtocolHandler.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUMCCPProtocolHandler.h"
#import "MUProtocolHandlerSubclass.h"

#include <zlib.h>

@interface MUMCCPProtocolHandler ()
{  
  z_stream *stream;
  
  uint8_t *inbuf;
  unsigned inalloc;
  unsigned insize;
  
  uint8_t *outbuf;
  unsigned outalloc;
  unsigned outsize;
}

@property (readonly) unsigned bytesPending;

- (void) cleanUpStream;
- (void) decompressInbuf;
- (void) decompressAfterClearingOutbuf;
- (void) log: (NSString *) message, ...;
- (void) maybeGrowInbuf: (unsigned) size;
- (void) maybeGrowOutbuf: (unsigned) size;
- (BOOL) initializeStream;

@end

#pragma mark -

@implementation MUMCCPProtocolHandler

@synthesize delegate;

+ (id) protocolHandlerWithConnectionState: (MUMUDConnectionState *) telnetConnectionState
{
  return [[self alloc] initWithConnectionState: telnetConnectionState];
}

- (id) initWithConnectionState: (MUMUDConnectionState *) telnetConnectionState
{
  if (!(self = [super init]))
    return nil;
  
  connectionState = telnetConnectionState;
  stream = NULL;
  insize = 0;
  outsize = 0;
  
  return self;
}

- (void) dealloc
{
  [self cleanUpStream];
  if (inbuf) free (inbuf);
  if (outbuf) free (outbuf);
}

#pragma mark - MUProtocolHandler overrides

- (void) parseByte: (uint8_t) byte
{
  if (!connectionState.isIncomingStreamCompressed)
  {
    [self passOnParsedByte: byte];
    return;
  }
  
  if (!stream)
  {
    if ([self initializeStream])
    {
      [self log: @"    MCCP: Decompression of incoming data started."];
      [self maybeGrowOutbuf: 2048];
    }
    else
    {
      // FIXME: Failing to initialize the stream is a fatal error. As in, should close this whole connection.
      return;
    }
  }
  
  [self maybeGrowInbuf: 1];
  memcpy (inbuf + insize, &byte, 1);
  insize += 1;
  
  [self decompressInbuf];
  
  while (self.bytesPending)
    [self decompressAfterClearingOutbuf];
}

#pragma mark - Private methods

@dynamic bytesPending;

- (unsigned) bytesPending
{
  return outsize;
}

- (void) cleanUpStream
{
  if (stream)
  {
    inflateEnd (stream);
    free (stream);
    stream = NULL;
  }
}

- (void) decompressAfterClearingOutbuf
{
  if (!outsize)
    return;
  
  for (unsigned i = 0; i < outsize; i++)
    [self passOnParsedByte: outbuf[i]];
  
  outsize = 0;
  
  [self decompressInbuf];
}

- (void) decompressInbuf
{
  if (!insize)
    return;
  
  stream->next_in = inbuf;
  stream->next_out = outbuf + outsize;
  stream->avail_in = insize;
  stream->avail_out = outalloc - outsize;
  
  int status = inflate (stream, Z_PARTIAL_FLUSH);
  
  if (status == Z_OK || status == Z_STREAM_END)
  {
    memmove (inbuf, stream->next_in, stream->avail_in);
    insize = stream->avail_in;
    outsize = (unsigned) (stream->next_out - outbuf);
    
    if (status == Z_STREAM_END)
    {
      [self maybeGrowOutbuf: insize];
      
      // Anything left in inbuf is uncompressed data.
      memcpy (outbuf + outsize, inbuf, insize);
      outsize += insize;
      insize = 0;
      
      [self cleanUpStream];
      [self log: @"    MCCP: Decompression of incoming data ended."];
      connectionState.isIncomingStreamCompressed = NO;
    }
    
    return;
  }
  
  if (status == Z_BUF_ERROR)
  {
    if (outsize * 2 > outalloc)
    {
      [self maybeGrowOutbuf: outalloc];
      [self decompressInbuf];
    }
    
    return;
  }
  
  // We have some other status error.
  // FIXME: This is a fatal error.
}

- (BOOL) initializeStream
{
  stream = (z_stream *) malloc (sizeof (z_stream));
  stream->zalloc = Z_NULL;
  stream->zfree = Z_NULL;
  stream->opaque = Z_NULL;
  stream->next_in = Z_NULL;
  stream->avail_in = 0;
  
  if (inflateInit (stream) != Z_OK)
  {
    // FIXME: This is also a fatal error.
    free (stream);
    stream = NULL;
    return NO;
  }
  
  return YES;
}

- (void) log: (NSString *) message, ...
{
  va_list args;
  va_start (args, message);
  
  [self.delegate log: message arguments: args];
  
  va_end (args);
}

- (void) maybeGrowOutbuf: (unsigned) bytes
{
  if (outbuf == NULL)
  {
    outbuf = malloc (bytes);
    outalloc = bytes;
  }
  else
  {
    unsigned old = outalloc;
    
    while (outalloc < outsize + bytes)
      outalloc *= 2;
    
    if (old != outalloc)
      outbuf = realloc (outbuf, outalloc);
  }
}

- (void) maybeGrowInbuf: (unsigned) bytes
{
  if (inbuf == NULL)
  {
    inbuf = malloc (bytes);
    inalloc = bytes;
  }
  else
  {
    unsigned old = inalloc;
    
    while (inalloc < insize + bytes)
      inalloc *= 2;
    
    if (old != inalloc)
      inbuf = realloc (inbuf, inalloc);
  }
}

@end
