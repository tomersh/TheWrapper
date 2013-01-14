//
//  TheWrapper.h
//
//  Created by Tomer Shiri on 1/10/13.
//  Copyright (c) 2013 Tomer Shiri. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TheWrapper : NSObject

+(void) addWrapperto:(id<NSObject>) target andSelector:(SEL) selector withPreRunBlock:(void (^)(va_list args)) preRunblock;
+(void) addWrapperto:(id<NSObject>) target andSelector:(SEL) selector withPostRunBlock:(id (^)(id functionReturnValue, va_list args)) postRunBlock;
+(void) addWrapperto:(id<NSObject>) target andSelector:(SEL) selector withPreRunBlock:(void (^)(va_list args)) preRunblock andPostRunBlock:(id (^)(id functionReturnValue, va_list args)) postRunBlock;

+(void) addWrappertoClass:(Class) clazz andSelector:(SEL) selector withPreRunBlock:(void (^)(va_list args)) preRunblock;
+(void) addWrappertoClass:(Class) clazz andSelector:(SEL) selector withPostRunBlock:(id (^)(id functionReturnValue, va_list args)) postRunBlock;
+(void) addWrappertoClass:(Class) clazz andSelector:(SEL) selector withPreRunBlock:(void (^)(va_list args)) preRunblock andPostRunBlock:(id (^)(id functionReturnValue, va_list args)) postRunBlock;

+(void) removeWrapperFrom:(id<NSObject>) target andSelector:(SEL) selector;
+(void) removeWrapperFromClass:(Class) clazz andSelector:(SEL) selector;

@end