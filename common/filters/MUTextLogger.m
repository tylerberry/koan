//
// MUTextLogger.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTextLogger.h"
#import "MUPlayer.h"
#import "MUWorld.h"

@interface MUTextLogger ()
{
  NSOutputStream *_outputStream;
}

- (void) _log: (NSAttributedString *) attributedString;
- (void) _initializeFileAtURL: (NSURL *) url withHeaders: (NSDictionary *) headers;
- (void) _writeToStream: (NSOutputStream *) stream withFormat: (NSString *) format, ...;

@end

#pragma mark -

@implementation MUTextLogger

+ (instancetype) filterWithWorld: (MUWorld *) world
{
  return [[self alloc] initWithWorld: world];
}

+ (instancetype) filterWithWorld: (MUWorld *) world player: (MUPlayer *) player
{
  return [[self alloc] initWithWorld: world player: player];
}

- (instancetype) initWithOutputStream: (NSOutputStream *) outputStream
{
  if (!outputStream || !(self = [super init]))
    return nil;
  
  _outputStream = outputStream;
  [_outputStream open];
  
  return self;
}

- (instancetype) init
{
  return [self initWithWorld: nil player: nil];
}

- (instancetype) initWithWorld: (MUWorld *) world
{
  return [self initWithWorld: world player: nil];
}

- (instancetype) initWithWorld: (MUWorld *) world player: (MUPlayer *) player
{
  NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
  NSString *todayString = [formatter stringFromDate: [NSDate date]];
  NSString *logFileName = [NSString stringWithFormat: @"%@%@%@.koanlog",
                           (world ? [NSString stringWithFormat: @"%@-", world.name] : @""),
                           (player ? [NSString stringWithFormat: @"%@-", player.name] : @""),
                           todayString];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSURL *logDirectoryURL = [NSURL URLWithString: [defaults objectForKey: MUPLogDirectoryURL]];
  NSURL *logURL = [logDirectoryURL URLByAppendingPathComponent: logFileName];
  
  NSMutableDictionary *headers = [NSMutableDictionary dictionary];
  [headers setValue: (world ? world.name : @"") forKey: @"World"];
  [headers setValue: (player ? player.name : @"") forKey: @"Player"];
  [headers setValue: todayString forKey: @"Date"];
  
  BOOL isDirectory;
  if (![[NSFileManager defaultManager] fileExistsAtPath: logDirectoryURL.path isDirectory: &isDirectory])
  {
    NSError *directoryCreationError;
    [[NSFileManager defaultManager] createDirectoryAtURL: logDirectoryURL
                             withIntermediateDirectories: YES
                                              attributes: nil
                                                   error: &directoryCreationError];
  }
  else if (!isDirectory)
  {
    NSLog (@"Warning: file already exists at log directory path.");
  }
  
  [self _initializeFileAtURL: logURL withHeaders: headers];
  
  return [self initWithOutputStream: [NSOutputStream outputStreamWithURL: logURL append: YES]];
}

- (void) dealloc
{
  [_outputStream close];
}

- (NSAttributedString *) filterCompleteLine: (NSAttributedString *) attributedString
{
  if (attributedString.length > 0)
    [self _log: attributedString];
  
  return attributedString;
}

- (NSAttributedString *) filterPartialLine: (NSAttributedString *) attributedString
{
  return attributedString;
}

#pragma mark - Private methods

- (void) _log: (NSAttributedString *) attributedString
{
  [self _writeToStream: _outputStream withFormat: @"%@", attributedString.string];
}

- (void) _initializeFileAtURL: (NSURL *) url withHeaders: (NSDictionary *) headers
{
  NSOutputStream *stream;
  
  if ([[NSFileManager defaultManager] fileExistsAtPath: url.path])
    return;
  
  stream = [NSOutputStream outputStreamToFileAtPath: url.path append: YES];
  [stream open];
  
  @try
  {
    for (NSString *key in headers.allKeys)
    {
      NSString *value = headers[key];
      if (value.length > 0)
        [self _writeToStream: stream withFormat: @"%@:  %@\n", key, headers[key]];
    }
    [self _writeToStream: stream withFormat: @"\n"];
  }
  @finally
  {
    [stream close];      
  }
}

- (void) _writeToStream: (NSOutputStream *) stream withFormat: (NSString *) format, ...
{
  va_list args;
  NSString *string;
  const char *buffer;
  
  va_start (args, format);
  string = [[NSString alloc] initWithFormat: format arguments: args];
  va_end (args);
  buffer = string.UTF8String;
  [stream write: (uint8_t *) buffer maxLength: strlen (buffer)];  
}

@end
