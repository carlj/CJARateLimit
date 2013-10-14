//
//  NSObject+RateLimit.h
//  CJARateLimit
//
//  Created by Carl Jahn on 14.10.13.
//  Copyright (c) 2013 Carl Jahn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CJALimitProxy : NSObject

- (void)setRateLimit:(NSTimeInterval)interval forSelector:(SEL)selector;
- (void)setRateLimit:(NSTimeInterval)interval forSelector:(SEL)selector persitent:(BOOL)persitent;

- (void)removeRateLimitForSelector:(SEL)selector;

@end

@interface NSObject (RateLimit)

@property (nonatomic, strong, readonly) id limitProxy;

@end
