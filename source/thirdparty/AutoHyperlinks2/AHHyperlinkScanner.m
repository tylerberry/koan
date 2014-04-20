//
// AutoHyperlinks Framework (c) 2004-2008 by the following:
//
//   Colin Barrett, Graham Booker, Jorge Salvador Caffarena, Evan Schoenberg, Augie Fackler, Stephen Holt, Peter Hosey,
//   Adam Iser, Jeffrey Melloy, Toby Peterson, Eric Richie, David Smith.
//
// License:
//
//   Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
//   following conditions are met:
//
//   * Redistributions of source code must retain the above copyright notice, this list of conditions and the following
//     disclaimer.
//   * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
//     following disclaimer in the documentation and/or other materials provided with the distribution.
//   * Neither the name of the AutoHyperlinks Framework nor the names of its contributors may be used to endorse or
//     promote products derived from this software without specific prior written permission.
//
//   THIS SOFTWARE IS PROVIDED BY ITS DEVELOPERS ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
//   EVENT SHALL ITS DEVELOPERS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//   DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
//   OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
//   TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//   POSSIBILITY OF SUCH DAMAGE.
//
// Modifications by Tyler Berry.
// Copyright (c) 2013 3James Software.
//

#import "AHHyperlinkScanner.h"
#import "AHLinkLexer.h"
#import "AHMarkedHyperlink.h"
#import "NSStringPunycodeAdditions.h"

#define DEFAULT_URL_SCHEME @"http://"
#define ENC_INDEX_KEY @"encIndex"
#define ENC_CHAR_KEY @"encChar"

#define MIN_LINK_LENGTH 4

#pragma mark - Static variables

static NSCharacterSet  *skipSet = nil;
static NSCharacterSet  *endSet = nil;
static NSCharacterSet  *startSet = nil;
static NSCharacterSet  *punctuationSet = nil;
static NSCharacterSet  *hostnameComponentSeparatorSet = nil;
static NSArray *enclosureStartArray = nil;
static NSArray *enclosureStopArray = nil;
static NSCharacterSet  *enclosureSet = nil;
static NSArray *enclosureKeys = nil;
static NSDictionary *_urlSchemes = nil;

#pragma mark -

@interface AHHyperlinkScanner ()
{
  NSString *_stringToScan;
  NSMutableArray *_openEnclosureStack;
#if TARGET_OS_IPHONE
  NSString *_linkifiedString;
#else
  NSAttributedString *_initialAttributedString;
  NSAttributedString *_linkifiedString;
#endif
  BOOL _strictChecking;

  NSLock *_linkifiedStringLock;
}

#if TARGET_OS_IPHONE
- (NSString *) _createLinkifiedString;
#else
- (NSAttributedString *) _createLinkifiedString;
#endif

- (NSRange) _longestBalancedEnclosureInRange: (NSRange) range;
- (BOOL)  _scanString: (NSString *) string
upToCharactersFromSet: (NSCharacterSet *) characterSet
            intoRange: (NSRange *) range
            fromIndex: (unsigned long *) index;
- (BOOL) _scanString: (NSString *) inString
   charactersFromSet: (NSCharacterSet *) characterSet
           intoRange: (NSRange *) range
           fromIndex: (unsigned long *) index;

@end

#pragma mark -

@implementation AHHyperlinkScanner

#pragma mark - Property definitions

@synthesize scanLocation = _scanLocation;
@dynamic linkifiedString;

#pragma mark - Runtime initialization

+ (void) initialize
{
  NSMutableCharacterSet *mutableSkipSet = [[NSMutableCharacterSet alloc] init];
  [mutableSkipSet formUnionWithCharacterSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  [mutableSkipSet formUnionWithCharacterSet: [NSCharacterSet illegalCharacterSet]];
  [mutableSkipSet formUnionWithCharacterSet: [NSCharacterSet controlCharacterSet]];
  [mutableSkipSet formUnionWithCharacterSet: [NSCharacterSet characterSetWithCharactersInString: @"<>"]];
  
  skipSet = [NSCharacterSet characterSetWithBitmapRepresentation: mutableSkipSet.bitmapRepresentation];
  
  endSet = [NSCharacterSet characterSetWithCharactersInString: @"\"',:;>)]}.?!@"];
  
  NSMutableCharacterSet *mutableStartSet = [[NSMutableCharacterSet alloc] init];
  [mutableStartSet formUnionWithCharacterSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  [mutableStartSet formUnionWithCharacterSet: [NSCharacterSet characterSetWithCharactersInString:
                                               [NSString stringWithFormat: @"\"'.,:;<?!-@%C%C",
                                                  (unichar) 0x2014, (unichar) 0x2013]]];
  
  startSet = [NSCharacterSet characterSetWithBitmapRepresentation: [mutableStartSet bitmapRepresentation]];
  
  punctuationSet = [NSCharacterSet characterSetWithCharactersInString: @"\"'.,:;<?!"];
  
  hostnameComponentSeparatorSet = [NSCharacterSet characterSetWithCharactersInString: @"./"];
  enclosureStartArray = @[@"(", @"[", @"{"];
  enclosureStopArray = @[@")", @"]", @"}"];
  enclosureSet = [NSCharacterSet characterSetWithCharactersInString: @"()[]{}"];
  enclosureKeys = @[ENC_INDEX_KEY, ENC_CHAR_KEY];
  
  _urlSchemes = @{@"ftp": @"ftp://"};
  
  [super initialize];
}

#pragma mark - Class methods

+ (id) hyperlinkScannerWithString: (NSString *) string
{
  return [[[self class] alloc] initWithString: string usingStrictChecking: NO];
}

+ (id) strictHyperlinkScannerWithString: (NSString *) string
{
  return [[[self class] alloc] initWithString: string usingStrictChecking: YES];
}

#if !TARGET_OS_IPHONE

+ (id) hyperlinkScannerWithAttributedString: (NSAttributedString *) attributedString
{
  return [[[self class] alloc] initWithAttributedString: attributedString usingStrictChecking: NO];
}

+ (id) strictHyperlinkScannerWithAttributedString: (NSAttributedString *) attributedString
{
  return [[[self class] alloc] initWithAttributedString: attributedString usingStrictChecking: YES];
}

#endif

#pragma mark - Init/Dealloc

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  _scanLocation = 0;
  _linkifiedString = nil;
#if !TARGET_OS_IPHONE
  _initialAttributedString = nil;
#endif
  _openEnclosureStack = [[NSMutableArray alloc] init];
  _linkifiedStringLock = [[NSLock alloc] init];
  
  return self;
}

- (id) initWithString: (NSString *) string usingStrictChecking: (BOOL) strictChecking
{
  if (!(self = [self init]))
    return nil;
  
  _stringToScan = [string copy];
  _strictChecking = strictChecking;
  
  return self;
}

#if !TARGET_OS_IPHONE

- (id) initWithAttributedString: (NSAttributedString *) attributedString usingStrictChecking: (BOOL) strictChecking
{
  if (!(self = [self init]))
    return nil;
  
  _stringToScan = [attributedString.string copy];
  _initialAttributedString = [attributedString copy];
  _strictChecking = strictChecking;
  
  return self;
}

#endif

- (void) dealloc
{
  _stringToScan = nil;
#if !TARGET_OS_IPHONE
  _initialAttributedString = nil;
#endif
  _linkifiedString = nil;
}

#pragma mark - URI verification

- (BOOL) isValidURI
{
  return [[self class] isStringValidURI: _stringToScan
                            usingStrict: _strictChecking
                              fromIndex: nil
                             withStatus: nil
                           schemeLength: nil];
}

+ (BOOL) isStringValidURI: (NSString *) string
              usingStrict: (BOOL) useStrictChecking
                fromIndex: (unsigned long *) sIndex
               withStatus: (AH_URI_VERIFICATION_STATUS *) validStatus
             schemeLength: (unsigned long *) schemeLength
{
  if (!validStatus)
  {
    AH_URI_VERIFICATION_STATUS newStatus = AH_URL_INVALID;
    validStatus = &newStatus;
  }
  
  *validStatus = AH_URL_INVALID; // assume the URL is invalid
  
  NSString *punycodedString = [string encodedURLString];
  
  // Find the fastest 8-bit wide encoding possible for the c string
  NSStringEncoding stringEncoding = [punycodedString fastestEncoding];
  
  if ([@" " lengthOfBytesUsingEncoding: stringEncoding] > 1U)
    stringEncoding = NSUTF8StringEncoding;
  
  const char *encodedCString;
  if (!(encodedCString = [punycodedString cStringUsingEncoding: stringEncoding]))
    return NO;
  
  unsigned long encodedLength = strlen (encodedCString); // length of the string in utf-8
  
  // initialize the buffer (flex automatically switches to the buffer in this function)
  yyscan_t scanner; // pointer to the flex scanner opaque type
  AHlex_init (&scanner);
  
  AH_BUFFER_STATE buf = AH_scan_string (encodedCString, scanner);
  
  // call flex to parse the input
  *validStatus = (AH_URI_VERIFICATION_STATUS) AHlex (scanner);
  if (sIndex)
    *sIndex += AHget_leng (scanner);
  if (schemeLength)
    *schemeLength = AHget_extra (scanner).schemeLength;
  
  // condition for valid URI's
  if (*validStatus == AH_URL_VALID || *validStatus == AH_MAILTO_VALID || *validStatus == AH_FILE_VALID)
  {
    AH_delete_buffer (buf, scanner); //remove the buffer from flex.
    buf = NULL; //null the buffer pointer for safty's sake.
    
    // check that the whole string was matched by flex.
    // this prevents silly things like "blah...com" from being seen as links
    if (AHget_leng (scanner) == (long) encodedLength)
    {
      AHlex_destroy (scanner);
      return YES;
    }
    // condition for degenerate URL's (A.K.A. URI's sans specifiers), requres strict checking to be NO.
  }
  else if ((*validStatus == AH_URL_DEGENERATE
            || *validStatus == AH_MAILTO_DEGENERATE
            || *validStatus == AH_URL_TENTATIVE)
           && !useStrictChecking)
  {
    AH_delete_buffer (buf, scanner);
    buf = NULL;
    
    if (AHget_leng (scanner) == (long) encodedLength)
    {
      AHlex_destroy (scanner);
      return YES;
    }
    // if it ain't valid, and it ain't degenerate, then it's invalid.
  }
  else
  {
    AH_delete_buffer (buf, scanner);
    buf = NULL;
    AHlex_destroy (scanner);
    return NO;
  }
  
  // default case, if the range checking above fails.
  AHlex_destroy (scanner);
  return NO;
}

#pragma mark - Accessors

- (AHMarkedHyperlink *) nextURI
{
  NSRange  scannedRange;
  unsigned long scannedLocation = self.scanLocation;
  
  // scan upto the next whitespace char so that we don't unnecessarily confuse flex
  // otherwise we end up validating urls that look like this "http://www.adium.im/ <--cool"
  [self _scanString: _stringToScan charactersFromSet: startSet intoRange: nil fromIndex: &scannedLocation];
  
  // main scanning loop
  while ([self _scanString: _stringToScan
     upToCharactersFromSet: skipSet
                 intoRange: &scannedRange
                 fromIndex: &scannedLocation])
  {
    if (MIN_LINK_LENGTH < scannedRange.length)
    {
      // Check for and filter enclosures.  We can't add (, [, etc. to the skipSet as they may be in a URI
      NSString *topEncChar = [_openEnclosureStack lastObject];
      if (topEncChar || [enclosureSet characterIsMember: [_stringToScan characterAtIndex: scannedRange.location]])
      {
        unsigned long encIdx = [enclosureStartArray indexOfObject: topEncChar ? topEncChar
                                                                              : [_stringToScan substringWithRange: NSMakeRange (scannedRange.location, 1)]];
        
        if (NSNotFound != encIdx)
        {
          NSRange encRange = [_stringToScan rangeOfString: enclosureStopArray[encIdx]
                                                  options: NSBackwardsSearch
                                                    range: scannedRange];
          
          if (NSNotFound != encRange.location)
          {
            scannedRange.length--;
            
            if (topEncChar)
              [_openEnclosureStack removeLastObject];
            else
            {
              scannedRange.location++;
              scannedRange.length--;
            }
          }
          else
          {
            [_openEnclosureStack addObject: enclosureStartArray[encIdx]];
          }
        }
      }
      if (!scannedRange.length)
        break;
      
      // Find balanced enclosure chars
      NSRange longestEnclosure = [self _longestBalancedEnclosureInRange: scannedRange];
      while (scannedRange.length > 2
             && [endSet characterIsMember: [_stringToScan characterAtIndex:
                                            (scannedRange.location + scannedRange.length - 1)]])
      {
        if ((longestEnclosure.location + longestEnclosure.length) < scannedRange.length)
          scannedRange.length--;
        else
          break;
      }
      
      // Update the scan location.
      self.scanLocation = scannedRange.location;
      
      // if we have a valid URL then save the scanned string, and make a SHMarkedHyperlink out of it.
      // this way, we can preserve things like the matched string (to be converted to a NSURL),
      // parent string, its validation status (valid, file, degenerate, etc), and its range in the parent string
      AH_URI_VERIFICATION_STATUS validStatus;
      NSString *_scanString = nil;
      unsigned long schemeLength = 0;
      
      if (MIN_LINK_LENGTH < scannedRange.length)
        _scanString = [_stringToScan substringWithRange: scannedRange];
      
      if ((MIN_LINK_LENGTH < scannedRange.length)
          && [AHHyperlinkScanner isStringValidURI: _scanString
                                      usingStrict: _strictChecking
                                        fromIndex: &_scanLocation
                                       withStatus: &validStatus
                                     schemeLength: &schemeLength])
      {
        AHMarkedHyperlink  *markedLink;
        BOOL makeLink = TRUE;
        
        //insert typical specifiers if the URL is degenerate
        switch (validStatus)
        {
          case AH_URL_DEGENERATE:
          {
            NSString *scheme = DEFAULT_URL_SCHEME;
            unsigned long i = 0;
            
            NSRange firstComponent;
            [self _scanString: _scanString
        upToCharactersFromSet: hostnameComponentSeparatorSet
                    intoRange: &firstComponent
                    fromIndex: &i];
            
            if (NSNotFound != firstComponent.location)
            {
              NSString *hostnameScheme = _urlSchemes[[_scanString substringWithRange: firstComponent]];
              if (hostnameScheme)
                scheme = hostnameScheme;
            }
            
            _scanString = [scheme stringByAppendingString: _scanString];
            
            break;
          }
            
          case AH_MAILTO_DEGENERATE:
            _scanString = [@"mailto:" stringByAppendingString: _scanString];
            break;
            
          case AH_URL_TENTATIVE:
          {
            NSString *scheme = [_scanString substringToIndex: schemeLength];
            NSArray *apps = (__bridge_transfer NSArray *) LSCopyAllHandlersForURLScheme ((__bridge CFStringRef) scheme);
            
            if (!apps.count)
              makeLink = FALSE;
            
            break;
          }
            
          default:
            break;
        }
        
        if (makeLink)
        {
          markedLink = [[AHMarkedHyperlink alloc] initWithString: _scanString
                                            withValidationStatus: validStatus
                                                    parentString: _stringToScan
                                                        andRange: scannedRange];
          return markedLink;
        }
      }
      
      // Step location after scanning a string
      NSRange startRange = [_stringToScan rangeOfCharacterFromSet: punctuationSet
                                                          options: NSLiteralSearch
                                                            range: scannedRange];
      if (startRange.location != NSNotFound)
        self.scanLocation = startRange.location + startRange.length;
      else
        self.scanLocation += scannedRange.length;
      
      scannedLocation = self.scanLocation;
    }
  }
  
  // if we're here, then NSScanner hit the end of the string
  // set AHStringOffset to the string length here so we avoid potential infinite looping with many trailing spaces.
  self.scanLocation = _stringToScan.length;
  return nil;
}

- (NSArray *) allURIs
{
  NSMutableArray *rangeArray = [NSMutableArray array];
  AHMarkedHyperlink  *markedLink;
  
  // Store the scan offset for restoration after calculating all URIs.
  unsigned long savedOffset = self.scanLocation;
  self.scanLocation = 0;
  
  //build an array of marked links.
  while ((markedLink = [self nextURI]))
  {
    [rangeArray addObject: markedLink];
  }
  
  self.scanLocation = savedOffset; // Reset to saved scan location.
  return rangeArray;
}

#if TARGET_OS_IPHONE

- (NSString *) linkifiedString
{
  NSString *returnValue = nil;
  
  [linkifiedStringLock lock];
  
  if (!_linkifiedString)
    _linkifiedString = [self _createLinkifiedString];
  
  returnValue = _linkifiedString;
  
  [linkifiedStringLock unlock];
  
  return returnValue;
}

#else

- (NSAttributedString *) linkifiedString
{
  NSAttributedString *returnValue = nil;
  
  [_linkifiedStringLock lock];
  
  if (!_linkifiedString)
    _linkifiedString = [self _createLinkifiedString];
  
  returnValue = _linkifiedString;
  
  [_linkifiedStringLock unlock];
  
  return returnValue;
}

#endif

#pragma mark - Below Here There Be Private Methods

#if TARGET_OS_IPHONE

-(NSString *) _createLinkifiedString
{
  NSMutableString *_linkifiedString;
  AHMarkedHyperlink *markedLink;
  unsigned long _scanLocationCache = self.scanLocation;
  NSEnumerator *linkEnumerator = self.allURIs.reverseObjectEnumerator;
  
  _linkifiedString = [[NSMutableString alloc] initWithString: m_scanString];
  
  while ((markedLink = [linkEnumerator nextObject]))
  {
    [_linkifiedString replaceCharactersInRange: markedLink.range
                                    withString: [NSString stringWithFormat: @"<a href=\"%@\">%@</a>",
                                                 markedLink.URL,
                                                 [m_scanString substringWithRange: markedLink.range]]];
  }
  
  self.scanLocation = _scanLocationCache;
  return [_linkifiedString copy];
}

#else

- (NSAttributedString *) _createLinkifiedString
{
  NSMutableAttributedString  *_newString;
  AHMarkedHyperlink *markedLink;
  BOOL _didFindLinks = NO;
  unsigned long _scanLocationCache = self.scanLocation;
  
  if (_initialAttributedString)
    _newString = [_initialAttributedString mutableCopy];
  else
    _newString = [[NSMutableAttributedString alloc] initWithString: _stringToScan];
  
  //for each SHMarkedHyperlink, add the proper URL to the proper range in the string.
  for (markedLink in self.allURIs)
  {
    if (markedLink)
    {
      _didFindLinks = YES;
      [_newString addAttribute: NSLinkAttributeName
                         value: markedLink.URL
                         range: markedLink.range];
    }
  }
  
  self.scanLocation = _scanLocationCache;
  
  return _didFindLinks ? _newString
  : _initialAttributedString ? _initialAttributedString
  : [[NSMutableAttributedString alloc] initWithString: _stringToScan];
}

#endif

- (NSRange) _longestBalancedEnclosureInRange: (NSRange) range
{
  NSMutableArray *enclosureStack = nil, *enclosureArray = nil;
  NSString *matchChar = nil;
  NSDictionary *encDict;
  unsigned long encScanLocation = range.location;
  
  while (encScanLocation < range.length + range.location)
  {
    [self _scanString: _stringToScan upToCharactersFromSet: enclosureSet intoRange: nil fromIndex: &encScanLocation];
    
    if (encScanLocation >= (range.location + range.length))
      break;
    
    matchChar = [_stringToScan substringWithRange: NSMakeRange (encScanLocation, 1)];
    
    if ([enclosureStartArray containsObject: matchChar])
    {
      encDict = [NSDictionary  dictionaryWithObjects: @[@(encScanLocation), matchChar]
                                            forKeys: enclosureKeys];
      if (!enclosureStack)
        enclosureStack = [NSMutableArray array];
      [enclosureStack addObject: encDict];
    }
    else if ([enclosureStopArray containsObject: matchChar])
    {
      NSEnumerator *encEnumerator = [enclosureStack objectEnumerator];
      
      while ((encDict = [encEnumerator nextObject]))
      {
        unsigned long encTagIndex = [(NSNumber *) encDict[ENC_INDEX_KEY] unsignedLongValue];
        unsigned long encStartIndex = [enclosureStartArray indexOfObjectIdenticalTo: encDict[ENC_CHAR_KEY]];
        
        if ([enclosureStopArray indexOfObjectIdenticalTo: matchChar] == encStartIndex)
        {
          NSRange encRange = NSMakeRange (encTagIndex, encScanLocation - encTagIndex + 1);
          if (!enclosureStack)
            enclosureStack = [NSMutableArray array];
          if (!enclosureArray)
            enclosureArray = [NSMutableArray array];
          [enclosureStack removeObject: encDict];
          [enclosureArray addObject: NSStringFromRange (encRange)];
          break;
        }
      }
    }
    
    if (encScanLocation < range.length + range.location)
      encScanLocation++;
  }
  return (enclosureArray && enclosureArray.count) ? NSRangeFromString (enclosureArray.lastObject)
                                                  : NSMakeRange (0, 0);
}

// functional replacement for -[NSScanner scanUpToCharactersFromSet:intoString:]

- (BOOL)  _scanString: (NSString *) inString
upToCharactersFromSet: (NSCharacterSet *) inCharSet
            intoRange: (NSRange *) outRangeRef
            fromIndex: (unsigned long *) idx
{
  unichar _curChar;
  NSRange _outRange;
  unsigned long  _scanLength = inString.length;
  unsigned long  _idx;
  
  if (_scanLength <= *idx)
    return NO;
  
  // Absorb skipSet
  for (_idx = *idx; _scanLength > _idx; _idx++)
  {
    _curChar = [inString characterAtIndex: _idx];
    if (![skipSet characterIsMember: _curChar])
      break;
  }
  
  // scanUpTo:
  for(*idx = _idx; _scanLength > _idx; _idx++)
  {
    _curChar = [inString characterAtIndex: _idx];
    if ([inCharSet characterIsMember: _curChar] || [skipSet characterIsMember: _curChar])
      break;
  }
  
  _outRange = NSMakeRange (*idx, _idx - *idx);
  *idx = _idx;
  
  if (_outRange.length)
  {
    if (outRangeRef)
      *outRangeRef = _outRange;
    return YES;
  }
  else
    return NO;
}

// functional replacement for -[NSScanner scanCharactersFromSet:intoString:]
- (BOOL) _scanString: (NSString *) inString
   charactersFromSet: (NSCharacterSet *) inCharSet
           intoRange: (NSRange *) outRangeRef
           fromIndex: (unsigned long *) idx
{
  unichar _curChar;
  NSRange _outRange;
  unsigned long  _scanLength = inString.length;
  unsigned long  _idx = *idx;
  
  if (_scanLength <= _idx)
    return NO;
  
  // Asorb skipSet
  for (_idx = *idx; _scanLength > _idx; _idx++)
  {
    _curChar = [inString characterAtIndex: _idx];
    if (![skipSet characterIsMember: _curChar])
      break;
  }
  
  // scanCharacters:
  for (*idx = _idx; _scanLength > _idx; _idx++)
  {
    _curChar = [inString characterAtIndex: _idx];
    if (![inCharSet characterIsMember: _curChar])
      break;
  }
  
  _outRange = NSMakeRange (*idx, _idx - *idx);
  *idx = _idx;
  
  if (_outRange.length)
  {
    if (outRangeRef)
      *outRangeRef = _outRange;
    return YES;
  }
  else
    return NO;
}
@end
