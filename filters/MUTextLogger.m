//
// MUTextLogger.m
//
// Copyright (c) 2012 3James Software.
//

#import "categories/NSFileManager (Recursive).h"
#import "MUTextLogger.h"
#import "MUPlayer.h"
#import "MUWorld.h"

@interface MUTextLogger (Private)

- (void) log: (NSAttributedString *) attributedString;
- (void) initializeFileAtPath: (NSString *) path withHeaders: (NSDictionary *) headers;
- (void) writeToStream: (NSOutputStream *) stream withFormat: (NSString *) format, ...;

@end

#pragma mark -

@implementation MUTextLogger

+ (MUFilter *) filterWithWorld: (MUWorld *) world
{
  return [[self alloc] initWithWorld: world];
}

+ (MUFilter *) filterWithWorld: (MUWorld *) world player: (MUPlayer *) player
{
  return [[self alloc] initWithWorld: world player: player];
}

- (id) initWithOutputStream: (NSOutputStream *) stream
{
  if (!stream || !(self = [super init]))
    return nil;
  
  output = stream;
  [output open];
  
  return self;
}

- (id) init
{
  return [self initWithWorld: nil player: nil];
}

- (id) initWithWorld: (MUWorld *) world
{
  return [self initWithWorld: world player: nil];
}

- (id) initWithWorld: (MUWorld *) world player: (MUPlayer *) player
{
  NSString *todayString = [[NSCalendarDate calendarDate] descriptionWithCalendarFormat: @"%Y-%m-%d"];
  NSString *path = [[NSString stringWithFormat: @"~/Library/Logs/Koan/%@%@%@.koanlog",
                     (world ? [NSString stringWithFormat: @"%@-", world.name] : @""),
                     (player ? [NSString stringWithFormat: @"%@-", player.name] : @""),
                     todayString] stringByExpandingTildeInPath];
  
  NSMutableDictionary *headers = [NSMutableDictionary dictionary];
  [headers setValue: (world ? world.name : @"") forKey: @"World"];
  [headers setValue: (player ? player.name : @"") forKey: @"Player"];
  [headers setValue: todayString forKey: @"Date"];
  
  [[NSFileManager defaultManager] createDirectoryAtPath: [path stringByDeletingLastPathComponent]
                                             attributes: nil
                                              recursive: YES];
  [self initializeFileAtPath: path withHeaders: headers];
  
  return [self initWithOutputStream: [NSOutputStream outputStreamToFileAtPath: path append: YES]];
}

- (void) dealloc
{
  [output close];
}

- (NSAttributedString *) filter: (NSAttributedString *) string
{
  if (string.length > 0)
    [self log: string];
  
  return string;
}

#pragma mark - Private methods

- (void) log: (NSAttributedString *) attributedString
{
  [self writeToStream: output withFormat: @"%@", attributedString.string];
}

- (void) initializeFileAtPath: (NSString *) path withHeaders: (NSDictionary *) headers
{
  NSOutputStream *stream;
  
  if ([[NSFileManager defaultManager] fileExistsAtPath: path])
    return;
  
  stream = [NSOutputStream outputStreamToFileAtPath: path append: YES];
  [stream open];
  
  @try
  {
    for (NSString *key in headers.allKeys)
    {
      NSString *value = [headers objectForKey: key];
      if (value.length > 0)
        [self writeToStream: stream withFormat: @"%@:  %@\n", key, [headers objectForKey: key]];
    }
    [self writeToStream: stream withFormat: @"\n"];      
  }
  @finally
  {
    [stream close];      
  }
}

- (void) writeToStream: (NSOutputStream *) stream withFormat: (NSString *) format, ...
{
  va_list args;
  NSString *string;
  const char *buffer;
  
  va_start (args, format);
  string = [[NSString alloc] initWithFormat: format arguments: args];
  va_end (args);
  buffer = [string UTF8String];
  [stream write: (uint8_t *) buffer maxLength: strlen (buffer)];  
}

@end
