//
// MUTextView.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

@protocol MUTextViewPasteDelegate;

@interface MUTextView : NSTextView

@property (weak) IBOutlet NSObject <MUTextViewPasteDelegate> *pasteDelegate;
@property (readonly) NSSize monospaceCharacterSize;

@end

#pragma mark -

@protocol MUTextViewPasteDelegate

@optional

- (BOOL) textView: (MUTextView *) textView insertText: (id) string;
- (BOOL) textView: (MUTextView *) textView pasteAsPlainText: (id) originalSender;

@end
