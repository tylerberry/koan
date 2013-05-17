//
// MUNaiveURLFilter.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUNaiveURLFilter.h"

#import "AutoHyperlinks.h"

@implementation MUNaiveURLFilter

+ (MUFilter *) filter
{
  return [[self alloc] init];
}

- (NSAttributedString *) filterCompleteLine: (NSAttributedString *) attributedString
{
  NSMutableAttributedString *linkStrippedString = [attributedString mutableCopy];
  
  [linkStrippedString removeAttribute: NSLinkAttributeName range: NSMakeRange (0, linkStrippedString.length)];
  
  AHHyperlinkScanner *scanner = [AHHyperlinkScanner strictHyperlinkScannerWithAttributedString: linkStrippedString];
  
  return [scanner linkifiedString];
}

- (NSAttributedString *) filterPartialLine: (NSAttributedString *) attributedString
{
  return attributedString;
  //return [self filterCompleteLine: attributedString];
}

@end
