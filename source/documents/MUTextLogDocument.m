//
// MUTextLogDocument.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUTextLogDocument.h"
#import "MULogBrowserWindowController.h"

static NSString *MUKoanLogWorld = @"com_3james_koan_log_world";
static NSString *MUKoanLogPlayer = @"com_3james_koan_log_player";

@interface MUTextLogDocument ()

@property (readonly) NSString *spotlightDisplayName;

- (NSUInteger) findEndOfHeaderLocation: (NSString *)string lineEnding: (NSString **) lineEnding;
- (BOOL) addKeyValuePairFromString: (NSString *) string toDictionary: (NSMutableDictionary *) dictionary;
- (BOOL) parse: (NSString *) string;

@end

#pragma mark -

@implementation MUTextLogDocument

@synthesize content, headers;
@dynamic spotlightDisplayName;

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  content = nil;
  headers = nil;
  
  return self;
}

- (id) mockInitWithString: (NSString *) string
{
  if (![self init])
    return nil;
  
  if (![self parse: string])
    return nil;
  
  return self;
}

#pragma mark - Accessors

- (NSString *) content
{
  return content;
}

- (void) fillDictionaryWithMetadata: (NSMutableDictionary *) dictionary
{
  if ([self headerForKey: @"World"])
    dictionary[MUKoanLogWorld] = [self headerForKey: @"World"];
  
  if ([self headerForKey: @"Player"])
    dictionary[MUKoanLogPlayer] = [self headerForKey: @"Player"];
  
  if ([self headerForKey: @"Date"])
    dictionary[(NSString *) kMDItemContentCreationDate] = [NSDate dateWithNaturalLanguageString: [self headerForKey: @"Date"]];
  
  dictionary[(NSString *) kMDItemDisplayName] = self.spotlightDisplayName;
  dictionary[(NSString *) kMDItemTextContent] = self.content;
}

- (NSString *) headerForKey: (id) key
{
  return headers[key];
}

#pragma mark - NSDocument overrides

- (NSData *) dataOfType: (NSString *) typeName error: (NSError **) error
{
  // TODO: Should this be a read-only type?
  return nil;
}

- (void) makeWindowControllers
{
  MULogBrowserWindowController *controller = [MULogBrowserWindowController sharedLogBrowserWindowController];
  
  [controller setDocument: self];
}

- (BOOL) readFromData: (NSData *) data ofType: (NSString *) typeName error: (NSError **) error
{
  NSString *fileDataAsString = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
  
  if ([self parse: fileDataAsString])
    return YES;
  
  /*
   TODO: Actually report an error here.
   
  if (error)
  {
    NSDictionary *errorDictionary = [NSDictionary dictionaryWithObject: @"Failed to create keyed archive for unknown reason."
                                                                forKey: NSLocalizedDescriptionKey];
    
    *error = [NSError errorWithDomain: @"invalid.whatever"  
                                 code: -1
                             userInfo: errorDictionary];
  }
   */
  
  return NO;
}

#pragma mark - Private methods

- (BOOL) addKeyValuePairFromString: (NSString *) string toDictionary: (NSMutableDictionary *) dictionary
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

- (NSUInteger) findEndOfHeaderLocation: (NSString *) string lineEnding: (NSString **) lineEnding
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

- (BOOL) parse: (NSString *) string
{
  // TODO: This should have an error field.
  NSMutableDictionary *workingHeaders = [NSMutableDictionary dictionary];
  NSString *lineEnding;
  
  NSUInteger endOfHeaders = [self findEndOfHeaderLocation: string lineEnding: &lineEnding];
  if (endOfHeaders == NSNotFound)
    return NO;
  
  NSArray *headerLines = [[string substringToIndex: endOfHeaders] componentsSeparatedByString: lineEnding];
  
  for (NSString *line in headerLines)
  {
    if (![self addKeyValuePairFromString: line toDictionary: workingHeaders])
      return NO;
  }
  
  headers = workingHeaders;
  
  content = [[string substringFromIndex: endOfHeaders + (2 * lineEnding.length)] copy];
  
  return YES;
}

- (NSString *) spotlightDisplayName
{
  // This string should be of the format "Player on Date" unless there is no player header
  // in which case it should be "World on Date" unless there is none, and then it should be
  // "Koan Log on Date".  If there is no date header, then we should just return nil to 
  // indicate that we don't want to override the setting.

  NSString *date = [self headerForKey: @"Date"];
  if (!date)
    return nil;
  
  NSString *name = [self headerForKey: @"Player"];
  if (!name)
    name = [self headerForKey: @"World"];
  if (!name)
    name = @"Koan Log";
  
  return [NSString stringWithFormat: @"%@ on %@", name, date];
}

@end
