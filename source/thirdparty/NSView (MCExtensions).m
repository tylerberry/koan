//
// NSView (MCExtensions).m
//
// Copyright (c) 2009 Mental Facility.
//
// Source from: <http://www.mentalfaculty.com/mentalfaculty/Blog/Entries/2009/11/14_NSViewController_and_the_Chain_of_Responsibility.html>
//

#import "NSView (MCExtensions).h"
#import "NSObject (MCExtensions).h"
#import <objc/runtime.h>

static NSString * const MCViewControllerKey = @"MCViewControllerKey";

@implementation NSView (MCExtensions)

- (NSViewController *) viewController
{
  return objc_getAssociatedObject (self, (__bridge const void *) MCViewControllerKey);
}

- (void) setViewController: (NSViewController *) newController
{
	NSResponder *oldControllerNextResponder = self.viewController.nextResponder;
  NSViewController *oldController = self.viewController;
  
	// Set associated object to nil, so that the setNextResponder: method effectively just calls
  // the original implementation.
  
  objc_setAssociatedObject (self, (__bridge const void *) MCViewControllerKey, nil, OBJC_ASSOCIATION_RETAIN);
  
  if (oldController)
  {
    self.nextResponder = oldControllerNextResponder;
    oldController.nextResponder = nil;
  }
  
  if (newController)
  {
    NSResponder *ownNextResponder = self.nextResponder;
    self.nextResponder = newController;
    newController.nextResponder = ownNextResponder;
  }
  
  objc_setAssociatedObject (self, (__bridge const void *) MCViewControllerKey, newController, OBJC_ASSOCIATION_RETAIN);
}

- (void) setNextResponder: (NSResponder *) newNextResponder
{
  if (self.viewController)
  {
    self.viewController.nextResponder = newNextResponder;
    return;
  }
  
  invokeSupersequent (newNextResponder); // This calls the original setNextResponder: method.
}

@end
