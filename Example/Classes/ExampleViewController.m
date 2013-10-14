//
//  ViewController.m
//  CJARateLimit
//
//  Created by Carl Jahn on 14.10.13.
//  Copyright (c) 2013 Carl Jahn. All rights reserved.
//

#import "ExampleViewController.h"
#import "NSObject+RateLimit.h"

@interface TestObject : NSObject

- (void)doSomething;

@end

@implementation TestObject

- (void)doSomething {
  
  NSLog(@"%s", __FUNCTION__);
}

@end

@interface ExampleViewController ()

@end

@implementation ExampleViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  TestObject *objTest = [TestObject new];
  
  [objTest.limitProxy setRateLimit:2.0f forSelector:@selector(doSomething)];
  
  [objTest.limitProxy doSomething]; //The doSomething Method get called

  [objTest.limitProxy doSomething]; //The doSomething Method doesnt get called

  
  double delayInSeconds = 3.0;
  __block typeof(TestObject) *blockTest = objTest;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    
    [blockTest.limitProxy doSomething]; //The doSomething Method get called
  });
  
}


@end
