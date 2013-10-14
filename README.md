#CJARateLimit
I liked the [SAMRateLimit](https://github.com/soffes/SAMRateLimit) Library RateLimit concept and adapt the concept. 

[![Build Status](https://travis-ci.org/carlj/CJARateLimit.png?branch=master)](https://travis-ci.org/carlj/CJARateLimit)
[![Coverage Status](https://coveralls.io/repos/carlj/CJARateLimit/badge.png?branch=master)](https://coveralls.io/r/carlj/CJARateLimit?branch=master)

##Installation
Just drag & drop the [`NSObject+RateLimit.h`](CJARateLimit/NSObject+RateLimit.h) and [`NSObject+RateLimit.m`](CJARateLimit/NSObject+RateLimit.m) to your project.

##Example
First of all take a look at the [Example Project](Example/Classes/ExampleViewController.m)

##Usage
``` objc
//import the header
#import "NSObject+RateLimit.h"
```

``` objc
//create or use your custom object
@interface TestObject : NSObject

- (void)doSomething;

@end

@implementation TestObject

- (void)doSomething {
  
  NSLog(@"%s", __FUNCTION__);
}

@end
```

``` objc
TestObject *objTest = [TestObject new];

//set the limit for a specific method
[objTest.limitProxy setRateLimit:2.0f forSelector:@selector(doSomething)];

//The doSomething Method get called
[objTest.limitProxy doSomething]; 

//The doSomething Method doesnt get called
[objTest.limitProxy doSomething]; 

double delayInSeconds = 3.0;
__block typeof(TestObject) *blockTest = objTest;
dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
dispatch_after(popTime, dispatch_get_main_queue(), ^(void){

	//The doSomething Method get called
	[blockTest.limitProxy doSomething]; 
});
```

##LICENSE
Released under the [MIT LICENSE](LICENSE)