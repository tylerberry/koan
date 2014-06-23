//
// MUGrowlService.h
//
// Copyright (c) 2013 3James Software.
//

#import <Growl/GrowlApplicationBridge.h>

@interface MUGrowlService : NSObject <GrowlApplicationBridgeDelegate>

+ (instancetype) defaultGrowlService;

+ (void) connectionOpenedForTitle: (NSString *) title;
+ (void) connectionClosedForTitle: (NSString *) title;
+ (void) connectionClosedByServerForTitle: (NSString *) title;
+ (void) connectionClosedByErrorForTitle: (NSString *) title error: (NSError *) error;

@end
