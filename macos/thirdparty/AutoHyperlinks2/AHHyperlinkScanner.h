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

#import "AHLinkLexer.h"

typedef void *yyscan_t;

extern long AHlex (yyscan_t yyscanner);
extern long AHlex_init (yyscan_t * ptr_yy_globals);
extern long AHlex_destroy (yyscan_t yyscanner);
extern long AHget_leng (yyscan_t scanner);
extern void AHset_in (FILE * in_str, yyscan_t scanner);
extern YY_EXTRA_TYPE AHget_extra (yyscan_t scanner);

typedef struct AH_buffer_state *AH_BUFFER_STATE;
extern void AH_switch_to_buffer(AH_BUFFER_STATE, yyscan_t scanner);
extern AH_BUFFER_STATE AH_scan_string (const char *, yyscan_t scanner);
extern void AH_delete_buffer(AH_BUFFER_STATE, yyscan_t scanner);

@class AHMarkedHyperlink;

@interface AHHyperlinkScanner : NSObject

@property (assign) unsigned long scanLocation;

#if TARGET_OS_IPHONE
@property (readonly) NSString *linkifiedString;
#else
@property (readonly) NSAttributedString *linkifiedString;
#endif

/*!
 * @brief Allocs and inits a new lax AHHyperlinkScanner with the given NSString
 *
 * @param string the scanner's string
 * @return a new AHHyperlinkScanner
 */
+ (id) hyperlinkScannerWithString: (NSString *) string;

/*!
 * @brief Allocs and inits a new strict AHHyperlinkScanner with the given NSString
 *
 * @param string the scanner's string
 * @return a new AHHyperlinkScanner
 */
+ (id) strictHyperlinkScannerWithString: (NSString *) string;

#if !TARGET_OS_IPHONE
/*!
 * @brief Allocs and inits a new lax AHHyperlinkScanner with the given attributed string
 *
 * @param attributedString the scanner's string
 * @return a new AHHyperlinkScanner
 */
+ (id) hyperlinkScannerWithAttributedString: (NSAttributedString *) attributedString;

/*!
 * @brief Allocs and inits a new strict AHHyperlinkScanner with the given attributed string
 *
 * @param attributedString the scanner's string
 * @return a new AHHyperlinkScanner
 */
+ (id) strictHyperlinkScannerWithAttributedString: (NSAttributedString *) attributedString;
#endif

/*!
 * @brief Determine the validity of a given string with a custom strictness
 *
 * @param string The string to be verified
 * @param strictChecking Use strict rules or not
 * @param index a pointer to the index the string starts at, for easy incrementing.
 * @return Boolean
 */
+ (BOOL) isStringValidURI: (NSString *) string
              usingStrict: (BOOL) strictChecking
                fromIndex: (unsigned long *) index
               withStatus: (AH_URI_VERIFICATION_STATUS *) verificationStatus
             schemeLength: (unsigned long *) schemeLength;

/*!
 * @brief Init
 *
 * Inits a new AHHyperlinkScanner object for a NSString with the set strict checking option.
 *
 * @param string the NSString to be scanned.
 * @param strictChecking Sets strict checking preference.
 * @return A new AHHyperlinkScanner.
 */
- (id) initWithString: (NSString *) string usingStrictChecking: (BOOL) strictChecking;

#if !TARGET_OS_IPHONE
/*!
 * @brief Init
 *
 * Inits a new AHHyperlinkScanner object for a NSAttributedString with the set strict checking option.
 *
 * param string the NSString to be scanned.
 * @param strictChecking Sets strict checking preference.
 * @return A new AHHyperlinkScanner.
 */
- (id) initWithAttributedString: (NSAttributedString *) attributedString usingStrictChecking: (BOOL) strictChecking;
#endif

/*!
 * @brief Determine the validity of the scanner's string using the set strictness
 *
 * @return Boolean
 */
- (BOOL) isValidURI;

/*!
 * @brief Returns a AHMarkedHyperlink representing the next URI in the scanner's string
 *
 * @return A new AHMarkedHyperlink.
 */
- (AHMarkedHyperlink *) nextURI;

/*!
 * @brief Fetches all the URIs from the scanner's string
 *
 * @return An array of AHMarkedHyperlinks representing each matched URL in the string or nil if no matches.
 */
- (NSArray *) allURIs;

#if TARGET_OS_IPHONE
/*!
 * @brief Scans the stored string for URIs then adds the link attribs and objects.
 * @return An autoreleased NSString.
 */
- (NSString *) linkifiedString;
#else
/*!
 * @brief Scans the stored string for URIs then adds the link attribs and objects.
 * @return An autoreleased NSAttributedString.
 */
- (NSAttributedString *) linkifiedString;
#endif

@end
