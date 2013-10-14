//
//  NSObject+RateLimit.m
//  CJARateLimit
//
//  Created by Carl Jahn on 14.10.13.
//  Copyright (c) 2013 Carl Jahn. All rights reserved.
//

#import "NSObject+RateLimit.h"
#import <objc/objc-runtime.h>

static void *NSObjectLimitProxyPropertyKey = &NSObjectLimitProxyPropertyKey;

NSString const *CJALimitProxyDictionaryRateLimitKey   = @"CJALimitProxyDictionaryRateLimitKey";
NSString const *CJALimitProxyDictionaryLastActiontKey = @"CJALimitProxyDictionaryLastActiontKey";
NSString const *CJALimitProxyDictionaryPersistensKey  = @"CJALimitProxyDictionaryPersistensKey";

@interface CJALimitProxy ()

@property (nonatomic, strong) NSMutableDictionary *limits;
@property (nonatomic, weak) NSObject *target;

@end

@implementation CJALimitProxy

- (id)initWithTarget:(NSObject *)target {
  
  self = [super init];
  if (self) {
    
    self.target = target;
    self.limits = [self limitsFromDisk];
  }
  return self;
}

- (void)setRateLimit:(NSTimeInterval)interval forSelector:(SEL)selector {
  
  [self setRateLimit:interval forSelector:selector persitent:NO];
}

- (void)setRateLimit:(NSTimeInterval)interval forSelector:(SEL)selector persitent:(BOOL)persitent {
  
  NSString *key = NSStringFromSelector(selector);
  
  NSDictionary *limit = @{
                          CJALimitProxyDictionaryRateLimitKey   : @(interval),
                          CJALimitProxyDictionaryPersistensKey  : @(persitent),
                          CJALimitProxyDictionaryLastActiontKey : [NSDate dateWithTimeIntervalSince1970: 0]
                          };
  
  self.limits[key] = limit;
  
  [self writeRateLimits];
}

- (void)removeRateLimitForSelector:(SEL)selector {
  
  NSString *key = NSStringFromSelector(selector);
  
  [self.limits removeObjectForKey: key];

  [self writeRateLimits];
}

- (void)setLastActionForSelector:(SEL)selector {
  
  NSString *key = NSStringFromSelector(selector);
  
  NSMutableDictionary *limit = [NSMutableDictionary dictionaryWithDictionary: self.limits[key] ];
  limit[CJALimitProxyDictionaryLastActiontKey] = [NSDate date];
  
  self.limits[key] = limit;
  
  [self writeRateLimits];
}

- (BOOL)rateLimitExcistsForSelector:(SEL)selector {
  NSString *key = NSStringFromSelector(selector);

  return !(!self.limits[key]);
}

- (BOOL)shouldInvoceMessageForSelector:(SEL)selector {
  
  if ([self rateLimitExcistsForSelector: selector]) {
    
    NSString *key = NSStringFromSelector(selector);
    NSDictionary *limit = self.limits[key];

    NSDate *lastAction = limit[CJALimitProxyDictionaryLastActiontKey];
    NSTimeInterval rateLimit = ((NSNumber *)limit[CJALimitProxyDictionaryRateLimitKey]).doubleValue;
    
    NSTimeInterval timeIntervalSinceLastAction = [lastAction timeIntervalSinceNow];
    
    if (fabs(timeIntervalSinceLastAction) > rateLimit) {
      [self setLastActionForSelector: selector];
      
      return YES;
    }
    
    return NO;
  }
  
  return YES;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
  
  if (![self.target respondsToSelector: anInvocation.selector]) {
    [super forwardInvocation: anInvocation];
    return;
  }
  
  if ([self shouldInvoceMessageForSelector: anInvocation.selector]) {
    [anInvocation invokeWithTarget: self.target];
  }
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)selector {
  
  NSMethodSignature* signature = [super methodSignatureForSelector: selector];
  if (!signature) {
    
    signature = [self.target methodSignatureForSelector:selector];
  }
  return signature;
}

- (void)writeRateLimits {
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
    NSURL *fileURL = [self fileURL];
    [self.limits writeToURL: fileURL atomically:YES];
  });
}

- (NSMutableDictionary *)limitsFromDisk {
  
  NSMutableDictionary *limitsDictionary = [[NSMutableDictionary alloc] initWithContentsOfURL: [self fileURL]];
  if (!limitsDictionary) {
    
    limitsDictionary = [NSMutableDictionary dictionary];
  }
	
  return limitsDictionary;
}

- (NSURL *)fileURL {
  
  NSFileManager *defaultManager = [NSFileManager defaultManager];
  NSURL *applicationDirectory = [[defaultManager URLsForDirectory: NSApplicationSupportDirectory inDomains: NSUserDomainMask] lastObject];
  NSURL *ratelimitsDirectory = [applicationDirectory URLByAppendingPathComponent: @"com.yti.CJARateLimit"];
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    
    if (![defaultManager fileExistsAtPath: ratelimitsDirectory.path]) {
      [defaultManager createDirectoryAtURL:ratelimitsDirectory withIntermediateDirectories:YES attributes:Nil error:nil];
    }
  });
  
  NSString *fileName = [NSString stringWithFormat:@"%@.plist", NSStringFromClass(self.target.class)];
  
  return [ratelimitsDirectory URLByAppendingPathComponent: fileName];
}

@end


@implementation NSObject (RateLimit)

- (id)limitProxy {
  
  CJALimitProxy *limitProxy = objc_getAssociatedObject(self, &NSObjectLimitProxyPropertyKey);
  if (!limitProxy) {
    
    limitProxy = [[CJALimitProxy alloc] initWithTarget: self];
    objc_setAssociatedObject(self, &NSObjectLimitProxyPropertyKey, limitProxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  
  return limitProxy;
}

@end
