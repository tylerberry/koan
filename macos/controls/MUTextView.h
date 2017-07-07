//
// MUTextView.h
//
// Copyright (c) 2013 3James Software.
//

@protocol MUTextViewPasteDelegate;

@interface MUTextView : NSTextView

@property (weak) IBOutlet NSObject <MUTextViewPasteDelegate> *pasteDelegate;

@property (readonly) NSSize monospaceCharacterSize;

@property (readonly) CGFloat monospaceCharacterWidth;
@property (readonly) CGFloat monospaceCharacterHeight;

@property (readonly) NSUInteger numberOfColumns;
@property (readonly) NSUInteger numberOfLines;

- (NSUInteger) numberOfColumnsForWidth: (CGFloat) width;
- (NSUInteger) numberOfLinesForHeight: (CGFloat) height;

- (CGFloat) minimumHeightForLines: (NSUInteger) numberOfLines;
- (CGFloat) minimumWidthForColumns: (NSUInteger) numberOfColumns;

- (void) scrollRangeToVisible: (NSRange) range animate: (BOOL) animateScrolling;

@end

#pragma mark -

@protocol MUTextViewPasteDelegate

@optional

- (BOOL) textView: (MUTextView *) textView insertText: (id) string;
- (BOOL) textView: (MUTextView *) textView pasteAsPlainText: (id) originalSender;
- (BOOL) textView: (MUTextView *) textView performFindPanelAction: (id) originalSender;

@end
