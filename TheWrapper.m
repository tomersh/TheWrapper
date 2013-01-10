//
//  TheWrapper.m
//
//  Created by Tomer Shiri on 1/10/13.
//  Copyright (c) 2013 Tomer Shiri. All rights reserved.
//

#import "TheWrapper.h"
#import <objc/runtime.h>

#define BLOCK_SAFE_RUN(block,...) block? block(__VA_ARGS__) : nil;

@interface WrappedFunctionData : NSObject

@property (nonatomic, copy) void (^preRunBlock)(va_list args);
@property (nonatomic, copy) id (^postRunBlock)(id functionReturnValue, va_list args);
@property (nonatomic) int functionPointer;
@end

@implementation WrappedFunctionData {
    void (^_preRunBlock)(va_list args);
    id (^_postRunBlock)(id functionReturnValue, va_list args);
    int _functionPointer;
}

@synthesize preRunBlock = _preRunBlock, postRunBlock = _postRunBlock, functionPointer = _functionPointer;

@end

@implementation TheWrapper

static NSMutableDictionary* _wrappedFunctions;

+(id) init {
    return nil;
}

+(void)initialize {
    _wrappedFunctions = [[NSMutableDictionary alloc] init];
}

+(BOOL) isInstance:(id) object {
    return class_isMetaClass(object_getClass(object));
}

+(BOOL) wasWrapped:(Class) clazz andSelector:(SEL) selector {
    NSNumber* pointer = [_wrappedFunctions objectForKey:[TheWrapper getStoredKeyForClass:clazz andSelector:selector]];
    return pointer ? YES : NO;
}

+(WrappedFunctionData*) createWrapperDataWith:(int) functionPointer andPreRunBlock:(void (^)(va_list args)) preRunblock andPostRunBlock:(id (^)(id functionReturnValue, va_list args)) postRunBlock{
    
    WrappedFunctionData* wrappedFunctionData = [[WrappedFunctionData alloc] init];
    wrappedFunctionData.functionPointer = functionPointer;
    wrappedFunctionData.preRunBlock = preRunblock;
    wrappedFunctionData.postRunBlock = postRunBlock;
    if (postRunBlock == nil) {
        wrappedFunctionData.postRunBlock = ^(id functionReturnValue, va_list args) { return functionReturnValue; };
    }
    return [wrappedFunctionData autorelease];
}


+(BOOL) addWrapperto:(id) target andSelector:(SEL) selector withPreRunBlock:(void (^)(va_list args)) preRunblock {
    return [TheWrapper addWrapperto:target andSelector:selector withPreRunBlock:preRunblock andPostRunBlock:nil];
}

+(BOOL) addWrapperto:(id) target andSelector:(SEL) selector withPostRunBlock:(id (^)(id functionReturnValue, va_list args)) postRunBlock {
    return [TheWrapper addWrapperto:target andSelector:selector withPreRunBlock:nil andPostRunBlock:postRunBlock];
}

+(BOOL) addWrapperto:(id) target andSelector:(SEL) selector withPreRunBlock:(void (^)(va_list args)) preRunblock andPostRunBlock:(id (^)(id functionReturnValue, va_list args)) postRunBlock {
    
    Class originalClass = [TheWrapper isInstance:target] ? [target class] : target;
    
    if ([TheWrapper wasWrapped:originalClass andSelector:selector]) return NO;
    
    Method originalMethod;
    
    if ([TheWrapper isInstance:target]) {
        originalMethod = class_getInstanceMethod(originalClass, selector);
    }
    else {
        originalMethod = class_getClassMethod(originalClass, selector);
    }
    
    void* originaImplementation = (void *)method_getImplementation(originalMethod);
    int* pointerToFunction = (void*)&originaImplementation;
    int pointerAddress = *pointerToFunction;
    
    
    WrappedFunctionData* wrappedFunctionData = [TheWrapper createWrapperDataWith:pointerAddress andPreRunBlock:preRunblock andPostRunBlock:postRunBlock];
    
    [_wrappedFunctions setValue:wrappedFunctionData forKey:[TheWrapper getStoredKeyForClass:originalClass andSelector:selector]];
    
    if(!class_addMethod(originalClass, selector, (IMP)WrapperFunction, method_getTypeEncoding(originalMethod)))
        method_setImplementation(originalMethod, (IMP)WrapperFunction);
    
    return YES;
}

+(NSString*) getStoredKeyForClass:(Class) clazz andSelector:(SEL) selector {
    return [NSString stringWithFormat:@"%@_%@",NSStringFromClass(clazz), NSStringFromSelector(selector)];
}

static id WrapperFunction(id self, SEL _cmd, ...)
{
    va_list args;
    va_start(args, _cmd);
    
    NSString* functionKey = [TheWrapper getStoredKeyForClass:[self class] andSelector:_cmd];
    
    WrappedFunctionData* wrappedFunctionData = [_wrappedFunctions objectForKey:functionKey];
    
    if (!wrappedFunctionData) return nil;
    
    BLOCK_SAFE_RUN(wrappedFunctionData.preRunBlock, args);
    
    int pointerAddress = wrappedFunctionData.functionPointer;
    
    id (*implementation)(id, SEL, ...) = (void *)*&pointerAddress;
    
    id functionReturnValue = implementation(self, _cmd, args);
    
    id returnValue = BLOCK_SAFE_RUN(wrappedFunctionData.postRunBlock, functionReturnValue, args);
    
    return returnValue;
}

@end
