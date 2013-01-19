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

-(id) initWithFunctionPointerAddress:(int) functionPointerAddress andPreRunBlock:(void (^)(va_list args)) preRunblock andPostRunBlock:(id (^)(id functionReturnValue, va_list args)) postRunBlock {
    self = [super init];
    if (!self) return self;
    self.functionPointer = functionPointerAddress;
    self.preRunBlock = preRunblock;
    self.postRunBlock = postRunBlock;
    return self;
}

-(void)dealloc {
    self.preRunBlock = nil;
    self.postRunBlock = nil;
    [super dealloc];
}

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

+(void) addWrapperto:(id<NSObject>) target andSelector:(SEL) selector withPreRunBlock:(void (^)(va_list args)) preRunblock {
    [TheWrapper addWrapperto:target andSelector:selector withPreRunBlock:preRunblock andPostRunBlock:nil];
}

+(void) addWrapperto:(id<NSObject>) target andSelector:(SEL) selector withPostRunBlock:(id (^)(id functionReturnValue, va_list args)) postRunBlock {
    [TheWrapper addWrapperto:target andSelector:selector withPreRunBlock:nil andPostRunBlock:postRunBlock];
}

+(void) addWrapperto:(id<NSObject>) target andSelector:(SEL) selector withPreRunBlock:(void (^)(va_list args)) preRunblock andPostRunBlock:(id (^)(id functionReturnValue, va_list args)) postRunBlock {
    
    Class clazz = [TheWrapper isInstance:target] ? [target class] : target;
    [TheWrapper addWrappertoClass:clazz andSelector:selector withPreRunBlock:preRunblock andPostRunBlock:postRunBlock];
}


+(void) addWrappertoClass:(Class) clazz andSelector:(SEL) selector withPreRunBlock:(void (^)(va_list args)) preRunblock {
    [TheWrapper addWrappertoClass:clazz andSelector:selector withPreRunBlock:preRunblock andPostRunBlock:nil];
}

+(void) addWrappertoClass:(Class) clazz andSelector:(SEL) selector withPostRunBlock:(id (^)(id functionReturnValue, va_list args)) postRunBlock {
    [TheWrapper addWrappertoClass:clazz andSelector:selector withPreRunBlock:nil andPostRunBlock:postRunBlock];
}


+(void) addWrappertoClass:(Class) clazz andSelector:(SEL) selector withPreRunBlock:(void (^)(va_list args)) preRunblock andPostRunBlock:(id (^)(id functionReturnValue, va_list args)) postRunBlock {
    
    Method originalMethod = class_getInstanceMethod(clazz, selector);

    if(originalMethod == nil) {
        originalMethod = class_getClassMethod(clazz, selector);
    }
    
    void* originaImplementation = (void *)method_getImplementation(originalMethod);
    int* pointerToFunction = (void*)&originaImplementation;
    int pointerAddress = *pointerToFunction;
    
    WrappedFunctionData* originFunctionWrapper = [_wrappedFunctions objectForKey:[TheWrapper getStoredKeyForClass:clazz andSelector:selector]];
    
    BOOL isAlreadyWrapped = originFunctionWrapper != nil;
    
    if(isAlreadyWrapped) {
        pointerAddress = originFunctionWrapper.functionPointer;
        return;
    }
    
    originFunctionWrapper = [[WrappedFunctionData alloc] initWithFunctionPointerAddress:pointerAddress andPreRunBlock:preRunblock andPostRunBlock:postRunBlock];

    [_wrappedFunctions setValue:originFunctionWrapper forKey:[TheWrapper getStoredKeyForClass:clazz andSelector:selector]];
    
    [originFunctionWrapper release];
        
    if(class_addMethod(clazz, selector, (IMP)WrapperFunction, method_getTypeEncoding(originalMethod))) {
         method_setImplementation(originalMethod, (IMP)WrapperFunction);
    }
    else {
        class_replaceMethod(clazz, selector, (IMP)WrapperFunction, method_getTypeEncoding(originalMethod));
    }
}

+(void) removeWrapperFrom:(id<NSObject>) target andSelector:(SEL) selector {
    Class clazz = [TheWrapper isInstance:target] ? [target class] : target;
    [TheWrapper removeWrapperFromClass:clazz andSelector:selector];
}

+(void) removeWrapperFromClass:(Class) clazz andSelector:(SEL) selector {
    [_wrappedFunctions removeObjectForKey:[TheWrapper getStoredKeyForClass:clazz andSelector:selector]];
}

+(NSString*) getStoredKeyForClass:(Class) clazz andSelector:(SEL) selector {
    return [NSString stringWithFormat:@"%@_%@",NSStringFromClass(clazz), NSStringFromSelector(selector)];
}


+ (WrappedFunctionData*) getFunctionData:(Class) clazz andSelector:(SEL) selector
{
    while(clazz)
    {
        WrappedFunctionData* wrappedFunctionData = [_wrappedFunctions objectForKey:[TheWrapper getStoredKeyForClass:clazz andSelector:selector]];
        if (wrappedFunctionData) return wrappedFunctionData;
        clazz = class_getSuperclass(clazz);
    }
    return nil;
}

static id WrapperFunction(id self, SEL _cmd, ...)
{
    id returnValue = nil;
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    va_list args;
    va_start(args, _cmd);
    
    WrappedFunctionData* wrappedFunctionData = [TheWrapper getFunctionData:[self class] andSelector:_cmd];
    
    if (!wrappedFunctionData) {
        [(NSObject*)self doesNotRecognizeSelector:_cmd];
        return self;
    }
    
    BLOCK_SAFE_RUN(wrappedFunctionData.preRunBlock, args);
    
    int pointerAddress = wrappedFunctionData.functionPointer;
    
    id (*implementation)(id, SEL, ...) = (void *)*&pointerAddress;
    
    returnValue = implementation(self, _cmd, args);
    
    if (wrappedFunctionData.postRunBlock != nil) {
        returnValue = BLOCK_SAFE_RUN(wrappedFunctionData.postRunBlock, returnValue, args);
    }
    
    [pool drain];
    return returnValue;
}

@end