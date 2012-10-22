//
// NSObject (MCExtensions).h
//
// Copyright (c) 2009 Mental Facility.
//
// Source from: <http://www.mentalfaculty.com/mentalfaculty/Blog/Entries/2009/11/14_NSViewController_and_the_Chain_of_Responsibility.html>
//

#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

#define invokeSupersequent(...) \
	([self getImplementationOf:_cmd \
		after:impOfCallingMethod(self, _cmd)]) \
		(self, _cmd, ##__VA_ARGS__)

@interface NSObject (MCExtensions)

IMP impOfCallingMethod (id lookupObject, SEL selector);
-(IMP) getImplementationOf:(SEL)lookup after:(IMP)skip;

@end
