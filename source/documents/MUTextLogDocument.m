//
// MUTextLogDocument.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTextLogDocument.h"

#import "MULogBrowserWindowController.h"
#import "MUTextLog.h"

@interface MUTextLogDocument ()
{
  MUTextLog *_textLog;
}

@end

#pragma mark -

@implementation MUTextLogDocument

@dynamic content, headers;

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  return self;
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
  
  _textLog = [[MUTextLog alloc] initWithString: fileDataAsString];
  
  if (!_textLog)
    return NO;
  
  return YES;
}

#pragma mark - Property pass-throughs

- (NSString *) content
{
  return _textLog.content;
}

- (void) setContent: (NSString *) newContent
{
  _textLog.content = newContent;
}

- (NSDictionary *) headers
{
  return _textLog.headers;
}

- (void) setHeaders: (NSDictionary *) newHeaders
{
  _textLog.headers = newHeaders;
}

@end
