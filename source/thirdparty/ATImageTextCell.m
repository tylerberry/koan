//
// ATImageTextCell.m
//
// Copyright (c) 2012 Apple Inc. All Rights Reserved.
// Version: 1.1
//
// License:
//
//   Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple") in consideration of your
//   agreement to the following terms, and your use, installation, modification or redistribution of this Apple software
//   constitutes acceptance of these terms. If you do not agree with these terms, please do not use, install, modify or
//   redistribute this Apple software.
//
//   In consideration of your agreement to abide by the following terms, and subject to these terms, Apple grants you a
//   personal, non-exclusive license, under Apple's copyrights in this original Apple software (the "Apple Software"), to
//   use, reproduce, modify and redistribute the Apple Software, with or without modifications, in source and/or binary
//   forms; provided that if you redistribute the Apple Software in its entirety and without modifications, you must
//   retain this notice and the following text and disclaimers in all such redistributions of the Apple Software. Neither
//   the name, trademarks, service marks or logos of Apple Inc. may be used to endorse or promote products derived from
//   the Apple Software without specific prior written permission from Apple. Except as expressly stated in this notice,
//   no other rights or licenses, express or implied, are granted by Apple herein, including but not limited to any
//   patent rights that may be infringed by your derivative works or by other works in which the Apple Software may be
//   incorporated.
//
//   The Apple Software is provided by Apple on an "AS IS" basis. APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED,
//   INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//   PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR
//   PRODUCTS.
//
//   IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
//   ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER
//   CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
//   APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Modifications by Tyler Berry.
// Copyright (c) 2012 3James Software.
//
// Notes:
//
//   Lots of stuff was removed from the original. The layout was changed, the subtitle was removed, the fill color box
//   was removed. This is basically a more sophisticated version of the classic "ImageAndTextCell".
//

#import "ATImageTextCell.h"

#define IMAGE_INSET 3.0
#define ASPECT_RATIO 1.0
#define INSET_FROM_IMAGE_TO_TEXT 3.0

#pragma mark -

@interface ATImageTextCell ()
{
  NSImageCell *_imageCell;
}

- (NSRect) _imageFrameForInteriorFrame: (NSRect) frame;
- (NSRect) _titleFrameForInteriorFrame: (NSRect) frame;

@end

#pragma mark -

@implementation ATImageTextCell

@dynamic image;

#pragma mark - Property accessors

- (NSImage *) image
{
  return _imageCell.image;
}

- (void) setImage: (NSImage *) image
{
  if (!_imageCell)
  {
    _imageCell = [[NSImageCell alloc] init];
    _imageCell.controlView = self.controlView;
    _imageCell.backgroundStyle = self.backgroundStyle;
  }
  
  _imageCell.image = image;
}

#pragma mark - Inherited method overrides

- (void) drawInteriorWithFrame: (NSRect) frame inView: (NSView *) controlView
{
  if (self.image)
  {
    NSRect imageFrame = [self _imageFrameForInteriorFrame: frame];
    [_imageCell drawWithFrame: imageFrame inView: controlView];
    
    NSRect titleFrame = [self _titleFrameForInteriorFrame: frame];
    [super drawInteriorWithFrame: titleFrame inView: controlView];
  }
  else
    [super drawInteriorWithFrame: frame inView: controlView];
}

- (void) editWithFrame: (NSRect) rect
                inView: (NSView *) controlView
                editor: (NSText *) editor
              delegate: (id) delegate
                 event: (NSEvent *) event
{
  if (self.image)
  {
    [super editWithFrame: [self _titleFrameForInteriorFrame: rect]
                  inView: controlView
                  editor: editor
                delegate: delegate
                   event: event];
  }
  else
    [super editWithFrame: rect inView: controlView editor: editor delegate: delegate event: event];
}

- (NSUInteger) hitTestForEvent: (NSEvent *) event inRect: (NSRect) rect ofView: (NSView *) controlView
{
  if (self.image)
  {
    NSPoint point = [controlView convertPoint: event. locationInWindow fromView:nil];
    
    // Delegate hit testing to other cells.
    
    NSRect imageFrame = [self _imageFrameForInteriorFrame: rect];
    if (NSPointInRect (point, imageFrame))
    {
      return [_imageCell hitTestForEvent: event inRect: imageFrame ofView: controlView];
    }
    
    NSRect titleFrame = [self _titleFrameForInteriorFrame: rect];
    if (NSPointInRect (point, titleFrame))
    {
      return [super hitTestForEvent: event inRect: titleFrame ofView: controlView];
    }
    
    return NSCellHitNone;
  }
  else
    return [super hitTestForEvent: event inRect: rect ofView: controlView];
}

- (NSRect) imageRectForBounds: (NSRect) frame
{
  // We would apply any inset that here that drawWithFrame: did before calling drawInteriorWithFrame:. It does none, so
  // we don't do anything.
  
  if (self.image)
    return [self _imageFrameForInteriorFrame: frame];
  else
    return NSZeroRect;
}

- (void) selectWithFrame: (NSRect) frame
                  inView: (NSView *) controlView
                  editor: (NSText *) editor
                delegate: (id) delegate
                   start: (NSInteger) selectionStart
                  length: (NSInteger) selectionLength
{
  if (self.image)
  {
    [super selectWithFrame: [self _titleFrameForInteriorFrame: frame]
                    inView: controlView
                    editor: editor
                  delegate: delegate
                     start: selectionStart
                    length: selectionLength];
  }
  else
  {
    [super selectWithFrame: frame
                    inView: controlView
                    editor: editor
                  delegate: delegate
                     start: selectionStart
                    length: selectionLength];
  }
}

- (void) setBackgroundStyle: (NSBackgroundStyle) style
{
  [super setBackgroundStyle: style];
  _imageCell.backgroundStyle = style;
}

- (void) setControlView: (NSView *) controlView
{
  [super setControlView: controlView];
  _imageCell.controlView = controlView;
}

#pragma mark - NSCopying protocol

- (id) copyWithZone: (NSZone *) zone
{
  ATImageTextCell *result = [super copyWithZone: zone];
  
  if (result != nil)
  {
    // Retain or copy all our ivars
    result->_imageCell = [_imageCell copyWithZone: zone];
  }
  
  return result;
}

#pragma mark - Private methods

- (NSRect) _imageFrameForInteriorFrame: (NSRect) frame
{
  NSRect result = frame;
  
  // Inset the top.
  result.origin.y += IMAGE_INSET;
  result.size.height -= 2 * IMAGE_INSET;
  
  // Inset the left.
  result.origin.x += IMAGE_INSET;
  
  // Make the width match the aspect ratio based on the height.
  result.size.width = ceil (result.size.height * ASPECT_RATIO);
  return result;
}

- (NSRect) _titleFrameForInteriorFrame: (NSRect) frame
{
  NSRect imageFrame = [self _imageFrameForInteriorFrame: frame];
  NSRect result = frame;
  
  // Move our inset to the left of the image frame.
  result.origin.x = NSMaxX (imageFrame) + INSET_FROM_IMAGE_TO_TEXT;
  
  // Go as wide as we can.
  result.size.width = NSMaxX (frame) - NSMinX (result);
  
  return result;
}

@end
