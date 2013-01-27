//
// GetMetadataForFile.m
//
// Copyright (c) 2013 3James Software.
//

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h> 
#include <Foundation/Foundation.h>

#import "MUTextLog.h"
#include "GetMetadataForFile.h"

Boolean
GetMetadataForFile (void *thisInterface,
                    CFMutableDictionaryRef attributes,
                    CFStringRef contentTypeUTI,
                    CFStringRef pathToFile)
{
  Boolean result = FALSE;
  @autoreleasepool
  {
    NSString *logString = [NSString stringWithContentsOfURL: [NSURL fileURLWithPath: (__bridge NSString *) pathToFile]
                                                   encoding: NSUTF8StringEncoding
                                                      error: nil];
    MUTextLog *textLog = [[MUTextLog alloc] initWithString: logString];
    
    if (textLog)
    {
      [textLog fillDictionaryWithMetadata: (__bridge NSMutableDictionary *) attributes];
      result = TRUE;
    }
    
    return result;
  }
}
