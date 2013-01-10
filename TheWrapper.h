//
//  TheWrapper.h
//
//  Created by Tomer Shiri on 1/10/13.
//  Copyright (c) 2013 Tomer Shiri. All rights reserved.
//

#import <Foundation/Foundation.h>

#define AddProfiler(target, selector) [NanoProfiler addProfiler:(target) andSelector:(selector)];

@interface TheWrapper : NSObject

+(void) addWrapperto:(id) target andSelector:(SEL) selector withPreRunBlock:(void (^)(va_list args)) preRunblock andPostRunBlock:(id (^)(id functionReturnValue, va_list args)) postRunBlock;

+(void) addWrapperto:(id) target andSelector:(SEL) selector withPreRunBlock:(void (^)(va_list args)) preRunblock;

+(void) addWrapperto:(id) target andSelector:(SEL) selector withPostRunBlock:(id (^)(id functionReturnValue, va_list args)) postRunBlock;

@end
