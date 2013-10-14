//
//  CJARateLimitTests.m
//  CJARateLimitTests
//
//  Created by Carl Jahn on 14.10.13.
//  Copyright (c) 2013 Carl Jahn. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSObject+RateLimit.h"

@interface TestObject : NSObject

- (void)doSomething:(NSNumber * __autoreleasing *)testNumber;

@end

@implementation TestObject

- (void)doSomething:(NSNumber * __autoreleasing *)testNumber {
  
  *testNumber = @(42);
}

@end

@interface CJALimitProxy ()

- (NSURL *)fileURL;

@end

@interface CJARateLimitTests : XCTestCase

@property (nonatomic, strong) TestObject *testObject;

@end

@implementation CJARateLimitTests

- (void)setUp {
  [super setUp];
  
  self.testObject = [TestObject new];
}

- (void)tearDown {
  
  self.testObject = nil;
  
  [super tearDown];
}

- (void)testRateLimitFirstCall {
  
  [self.testObject.limitProxy setRateLimit: 1.0 forSelector: @selector(doSomething:) persitent: NO];
  
  NSNumber *testNumber = @(0);
  
  [self.testObject.limitProxy doSomething: &testNumber];
  
  XCTAssertEqualObjects(testNumber, @(42), @"method doesnt get called");
}

- (void)testRateLimitSecondCall {

  [self.testObject.limitProxy setRateLimit: 1.0 forSelector: @selector(doSomething:) persitent: NO];
  
  NSNumber *testNumber = @(0);
  
  [self.testObject.limitProxy doSomething: &testNumber];
  
  XCTAssertEqualObjects(testNumber, @(42), @"method doesnt get called");
  
  testNumber = @(0);
  [self.testObject.limitProxy doSomething: &testNumber];
  
  XCTAssertEqualObjects(testNumber, @(0), @"method get called");
}

- (void)testRateLimitWaitForThirdCall {

  [self.testObject.limitProxy setRateLimit: 1.0 forSelector: @selector(doSomething:) persitent: NO];
  
  NSNumber *testNumber = @(0);
  
  [self.testObject.limitProxy doSomething: &testNumber];
  
  XCTAssertEqualObjects(testNumber, @(42), @"method doesnt get called");
  
  testNumber = @(0);
  [self.testObject.limitProxy doSomething: &testNumber];
  
  XCTAssertEqualObjects(testNumber, @(0), @"method get called");
  
  sleep(2);
  
  [self.testObject.limitProxy doSomething: &testNumber];
  XCTAssertEqualObjects(testNumber, @(42), @"method get called");
}

- (void)testPersistence {

  [self.testObject.limitProxy setRateLimit: 2.0 forSelector: @selector(doSomething:) persitent: YES];

  NSURL *fileURL = [self.testObject.limitProxy fileURL];
  self.testObject = nil;
  
  NSDictionary *allLimits = [[NSDictionary alloc] initWithContentsOfURL: fileURL];
  NSDictionary *limit = allLimits[NSStringFromClass([TestObject class])];
  
  XCTAssertNil(limit, @"persistence dictionary isnt correct");
}

@end
