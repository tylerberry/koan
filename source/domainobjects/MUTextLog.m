//
// MUTextLog.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTextLog.h"

static NSString * const MUKoanLogWorldIdentifier = @"com_3james_koan_log_world";
static NSString * const MUKoanLogPlayerIdentifier = @"com_3james_koan_log_player";

@interface MUTextLog ()

@property (readonly) NSString *_spotlightDisplayName;

- (BOOL) _addKeyValuePairFromString: (NSString *) string toDictionary: (NSMutableDictionary *) dictionary;
- (NSUInteger) _findEndOfHeaderLocation: (NSString *)string lineEnding: (NSString **) lineEnding;
- (BOOL) _parse: (NSString *) string;

@end

#pragma mark -

@implementation MUTextLog

- (id) initWithString: (NSString *) string
{
  if (!(self = [super init]))
    return nil;
  
  [self _parse: string];
  
  return self;
}

- (void) fillDictionaryWithMetadata: (NSMutableDictionary *) dictionary
{
  if (self.headers[@"World"])
    dictionary[MUKoanLogWorldIdentifier] = self.headers[@"World"];
  
  if (self.headers[@"Player"])
    dictionary[MUKoanLogPlayerIdentifier] = self.headers[@"Player"];
  
  if (self.headers[@"Date"])
    dictionary[(NSString *) kMDItemContentCreationDate] = [NSDate dateWithNaturalLanguageString: self.headers[@"Date"]];
  
  dictionary[(NSString *) kMDItemDisplayName] = self._spotlightDisplayName;
  dictionary[(NSString *) kMDItemTextContent] = self.content;
}

#pragma mark - Private methods

- (BOOL) _addKeyValuePairFromString: (NSString *) string toDictionary: (NSMutableDictionary *) dictionary
{
  NSScanner *scanner = [NSScanner scannerWithString: string];
  NSString *header;
  
  [scanner scanUpToString: @":" intoString: &header];
  
  BOOL result = string.length > header.length;
  if (result)
  {
    NSString *value = [[string substringFromIndex: scanner.scanLocation + 2] stringByTrimmingCharactersInSet:
                       [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    dictionary[header] = value;
  }
  return result;
}

- (NSUInteger) _findEndOfHeaderLocation: (NSString *) string lineEnding: (NSString **) lineEnding
{
  *lineEnding = nil;
  
  NSRange range = [string rangeOfString: @"\n\n"];
  if (range.location != NSNotFound)
  {
    *lineEnding = @"\n";
    return range.location;
  }
  
  range = [string rangeOfString: @"\r\n\r\n"];
  if (range.location != NSNotFound)
  {
    *lineEnding = @"\r\n";
    return range.location;
  }
  
  range = [string rangeOfString: @"\r\r"];
  if (range.location != NSNotFound)
  {
    *lineEnding = @"\r";
    return range.location;
  }
  
  return NSNotFound;
}

- (BOOL) _parse: (NSString *) string
{
  // TODO: This should have an error field.
  NSMutableDictionary *workingHeaders = [NSMutableDictionary dictionary];
  NSString *lineEnding;
  
  NSUInteger endOfHeaders = [self _findEndOfHeaderLocation: string lineEnding: &lineEnding];
  if (endOfHeaders == NSNotFound)
    return NO;
  
  NSArray *headerLines = [[string substringToIndex: endOfHeaders] componentsSeparatedByString: lineEnding];
  
  for (NSString *line in headerLines)
  {
    if (![self _addKeyValuePairFromString: line toDictionary: workingHeaders])
      return NO;
  }
  
  self.headers = workingHeaders;
  
  self.content = [string substringFromIndex: endOfHeaders + (2 * lineEnding.length)];
  
  return YES;
}

#pragma mark - Private property implementation

- (NSString *) spotlightDisplayName
{
  // This string should be of the format "Player on Date" unless there is no player header
  // in which case it should be "World on Date" unless there is none, and then it should be
  // "Koan Log on Date".  If there is no date header, then we should just return nil to
  // indicate that we don't want to override the setting.
  
  NSString *date = self.headers[@"Date"];
  if (!date)
    return nil;
  
  NSString *name = self.headers[@"Player"];
  if (!name)
    name = self.headers[@"World"];
  if (!name)
    name = @"Koan Log";
  
  return [NSString stringWithFormat: @"%@ on %@", name, date];
}

@end
