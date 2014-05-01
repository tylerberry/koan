//
// MUMCCPProtocolHandler.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUMCCPProtocolHandler.h"
#import "MUProtocolHandlerSubclass.h"

#include <zlib.h>

@interface MUMCCPProtocolHandler ()
{
  MUMUDConnectionState *_connectionState;
  
  struct z_stream_s *_stream;
  
  uint8_t *_inbuf;
  unsigned _inalloc;
  unsigned _insize;
  
  uint8_t *_outbuf;
  unsigned _outalloc;
  unsigned _outsize;
}

@property (readonly) size_t bytesPending;

- (void) _cleanUpStream;
- (void) _decompress;
- (BOOL) _initializeStream;
- (void) _log: (NSString *) message, ...;
- (void) _maybeGrowInbuf: (unsigned) size;
- (void) _maybeGrowOutbuf: (unsigned) size;
- (void) _processOutbuf;

@end

#pragma mark -

@implementation MUMCCPProtocolHandler

+ (id) protocolHandlerWithConnectionState: (MUMUDConnectionState *) connectionState
{
  return [[self alloc] initWithConnectionState: connectionState];
}

- (id) initWithConnectionState: (MUMUDConnectionState *) connectionState
{
  if (!(self = [super init]))
    return nil;
  
  _connectionState = connectionState;
  _stream = NULL;
  
  _inbuf = NULL;
  _inalloc = 0;
  _insize = 0;
  
  _outbuf = NULL;
  _outalloc = 0;
  _outsize = 0;
  
  return self;
}

- (void) dealloc
{
  [self _cleanUpStream];
  if (_inbuf) free (_inbuf);
  if (_outbuf) free (_outbuf);
}

#pragma mark - MUProtocolHandler overrides

- (void) parseByte: (uint8_t) byte
{
  if (!_connectionState.isIncomingStreamCompressed)
  {
    PASS_ON_PARSED_BYTE (byte);
    return;
  }
  
  if (!_stream)
  {
    if ([self _initializeStream])
    {
      [self _log: @"    MCCP: Decompression of incoming data started."];
      [self _maybeGrowOutbuf: 2048];
    }
    else
    {
      // FIXME: Failing to initialize the stream is a fatal error. As in, should close this whole connection.
      return;
    }
  }
  
  [self _maybeGrowInbuf: 1];
  memcpy (_inbuf + _insize, &byte, 1);
  _insize++;
  
  [self _decompress];
  
  while (self.bytesPending)
  {
    [self _processOutbuf];
    [self _decompress];
  }
}

- (void) reset
{
  [self _cleanUpStream];
}

#pragma mark - Private methods

@dynamic bytesPending;

- (size_t) bytesPending
{
  return _outsize;
}

- (void) _cleanUpStream
{
  if (_stream)
  {
    inflateEnd (_stream);
    free (_stream);
    _stream = NULL;
  }
}

- (void) _decompress
{
  if (_insize == 0)
    return;
  
  _stream->next_in = _inbuf;
  _stream->next_out = _outbuf + _outsize;
  _stream->avail_in = _insize;
  _stream->avail_out = _outalloc - _outsize;
  
  int status = inflate (_stream, Z_PARTIAL_FLUSH);
  
  if (status == Z_OK || status == Z_STREAM_END)
  {
    memmove (_inbuf, _stream->next_in, _stream->avail_in);
    _insize = _stream->avail_in;
    _outsize = (unsigned) (_stream->next_out - _outbuf);
    
    if (status == Z_STREAM_END)
    {
      [self _maybeGrowOutbuf: _insize];
      
      // Anything left in inbuf is uncompressed data.
      memcpy (_outbuf + _outsize, _inbuf, _insize);
      _outsize += _insize;
      _insize = 0;
      
      [self _cleanUpStream];
      [self _log: @"    MCCP: Decompression of incoming data ended."];
      _connectionState.isIncomingStreamCompressed = NO;
    }
    
    return;
  }
  
  if (status == Z_BUF_ERROR)
  {
    if (_outsize * 2 > _outalloc)
    {
      [self _maybeGrowOutbuf: _outalloc];
      [self _decompress];
    }
    return;
  }
  
  // We have some other status error.
  // FIXME: This is a fatal error.
}

- (BOOL) _initializeStream
{
  _stream = (z_stream *) malloc (sizeof (z_stream));
  _stream->zalloc = Z_NULL;
  _stream->zfree = Z_NULL;
  _stream->opaque = Z_NULL;
  _stream->next_in = Z_NULL;
  _stream->avail_in = 0;
  
  if (inflateInit (_stream) != Z_OK)
  {
    // FIXME: This is also a fatal error.
    free (_stream);
    _stream = NULL;
    return NO;
  }
  
  return YES;
}

- (void) _log: (NSString *) message, ...
{
  va_list args;
  va_start (args, message);
  
  [self.delegate log: message arguments: args];
  
  va_end (args);
}

- (void) _maybeGrowOutbuf: (unsigned) bytes
{
  if (_outbuf == NULL)
  {
    _outbuf = malloc (bytes);
    _outalloc = bytes;
  }
  else
  {
    size_t old = _outalloc;
    
    while (_outalloc < _outsize + bytes)
      _outalloc *= 2;
    
    if (old != _outalloc)
      _outbuf = realloc (_outbuf, _outalloc);
  }
}

- (void) _maybeGrowInbuf: (unsigned) bytes
{
  if (_inbuf == NULL)
  {
    _inbuf = malloc (bytes);
    _inalloc = bytes;
  }
  else
  {
    size_t old = _inalloc;
    
    while (_inalloc < _insize + bytes)
      _inalloc *= 2;
    
    if (old != _inalloc)
      _inbuf = realloc (_inbuf, _inalloc);
  }
}

- (void) _processOutbuf
{
  if (!_outsize)
    return;
  
  for (unsigned i = 0; i < _outsize; i++)
    PASS_ON_PARSED_BYTE (_outbuf[i]);
  
  _outsize = 0;
}

@end
