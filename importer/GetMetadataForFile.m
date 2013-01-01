//
// GetMetadataForFile.m
//
// Copyright (c) 2013 3James Software.
//

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h> 
#include <Foundation/Foundation.h>

#import "MUTextLogDocument.h"
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
    MUTextLogDocument *logDocument = [[MUTextLogDocument alloc]
                                      initWithContentsOfURL: [NSURL fileURLWithPath: (__bridge NSString *) pathToFile]
                                      ofType: nil
                                      error: nil];
    
    if (logDocument)
    {
      [logDocument fillDictionaryWithMetadata: (__bridge NSMutableDictionary *) attributes];
      result = TRUE;
    }
    
    return result;
  }
}
