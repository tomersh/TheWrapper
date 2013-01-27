TheWrapper
==========

An objective C utility that lets you add a wrapper to any function.

##What is it?

Suppose you have the following method
```objectivec
//MyClass.m

-(void) foo {
  NSLog(@"My name is Mike");
}
```

with TheWrapper you can add a wrapper to foo in runtime.
Just add the following code before the first call to the function.
```objectivec
//MyClass.m

#import "TheWrapper.h"

+(void) initialize {
    [TheWrapper addWrappertoClass:[MyClass class] andSelector:@selector(foo) withPreRunBlock:^(id<NSObject> zelf, id firstArg, ...) {
    {
        NSLog(@"Hi,");
    }
    andPostRunBlock:^id(id<NSObject> zelf, id functionReturnValue, id firstArg, ...) {
    {
        NSLog(@"Bye.");
    }];
}
```

Now, calling foo will print
```objectivec
[self foo];

//Hi,
//My name is Mike
//Bye,
```

The original function's return value is accessible to the `PostRunBlock` via the `functionReturnValue` parameter.
If you wish to return the original return value, just return it from the `PostRunBlock`.

##Examples
[NanoProfiler](https://github.com/tomersh/NanoProfiler) is the first public usage of theWrapper. 

##Known issues

1. No arc support
2. Wrapping a method that is only implemented in superclass results in a EXC_BAD_ACCESS.
