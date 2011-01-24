//
// MUTextView.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>

@interface MUTextView : NSTextView

@end

#pragma mark -

@protocol MUTextViewDelegate

@optional

- (BOOL) textView: (MUTextView *) textView insertText: (id) string;
- (BOOL) textView: (MUTextView *) textView pasteAsPlainText: (id) originalSender;

@end
