//
// NSObject (MCExtensions).m
//
// Copyright (c) 2009 Mental Facility.
//
// Source from: <http://www.mentalfaculty.com/mentalfaculty/Blog/Entries/2009/11/14_NSViewController_and_the_Chain_of_Responsibility.html>
//

#import "NSObject (MCExtensions).h"
#import <objc/objc-class.h>

@implementation NSObject (MCExtensions)

IMP
impOfCallingMethod (id lookupObject, SEL selector)
{
  NSUInteger returnAddress = (NSUInteger) __builtin_return_address (0);
  NSUInteger closest = 0;
  
  // Iterate over the class and all superclasses.
  
  Class currentClass = object_getClass (lookupObject);
  while (currentClass)
  {
    // Iterate over all instance methods for this class.
    
    unsigned int methodCount;
    Method *methodList = class_copyMethodList (currentClass, &methodCount);
    
    for (unsigned i = 0; i < methodCount; i++)
    {
      // Ignore methods with different selectors.
      
      if (method_getName (methodList[i]) != selector)
        continue;
      
      // If this address is closer, use it instead.
      
      NSUInteger address = (NSUInteger) method_getImplementation (methodList[i]);
      if (address < returnAddress && address > closest)
        closest = address;
    }
    
    free (methodList);
    currentClass = class_getSuperclass (currentClass);
  }
  
  return (IMP) closest;
}

// Lookup the next implementation of the given selector after the
// default one. Returns nil if no alternate implementation is found.

- (IMP) getImplementationOf: (SEL) lookup after: (IMP) skip
{
  BOOL found = NO;
  
  Class currentClass = object_getClass (self);
  while (currentClass)
  {
    // Get the list of methods for this class
    
    unsigned methodCount;
    Method *methodList = class_copyMethodList (currentClass, &methodCount);
    
    // Iterate over all methods
    
    for (unsigned i = 0; i < methodCount; i++)
    {
      // Look for the selector.
      
      if (method_getName (methodList[i]) != lookup)
        continue;
      
      IMP implementation = method_getImplementation(methodList[i]);
      
      // Check if this is the "skip" implementation.
      
      if (implementation == skip)
        found = YES;
      
      else if (found)
      {
        // Return the match.
        
        free (methodList);
        return implementation;
      }
    }
    
    // No match found. Traverse up through super class' methods.
    free (methodList);
    
    currentClass = class_getSuperclass (currentClass);
  }
  return nil;
}

@end
