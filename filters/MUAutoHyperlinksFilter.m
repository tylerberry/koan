//
// MUAutoHyperlinksFilter.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUAutoHyperlinksFilter.h"

#import "AutoHyperlinks.h"

@implementation MUAutoHyperlinksFilter

+ (MUFilter *) filter
{
  return [[self alloc] init];
}

- (NSAttributedString *) filterCompleteLine: (NSAttributedString *) attributedString
{
  NSMutableAttributedString *linkStrippedString = [attributedString mutableCopy];
  
  [linkStrippedString removeAttribute: NSLinkAttributeName range: NSMakeRange (0, linkStrippedString.length)];
  
  AHHyperlinkScanner *scanner = [AHHyperlinkScanner hyperlinkScannerWithAttributedString: linkStrippedString];
  
  return [scanner linkifiedString];
}

- (NSAttributedString *) filterPartialLine: (NSAttributedString *) attributedString
{
  return [self filterCompleteLine: attributedString];
}

@end
