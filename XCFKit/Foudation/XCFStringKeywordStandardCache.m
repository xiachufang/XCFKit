//
//  XCFStringKeywordStandardCache.m
//  XCFKit iOS
//
//  Created by Guoyin Lee on 29/08/2017.
//  Copyright © 2017 XiaChuFang. All rights reserved.
//

#import "XCFStringKeywordStandardCache.h"

@implementation XCFStringKeywordStandardCache {
    NSCache *_cache;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _cache = [NSCache new];
        _cache.name = [NSString stringWithFormat:@"%@-%@", NSStringFromClass(self.class), [[NSUUID UUID] UUIDString]];
    }

    return self;
}

- (NSString *)valueForKeyword:(NSString *)keyword {
    return [_cache objectForKey:keyword];
}

- (void)cacheValue:(NSString *)value forKeyword:(NSString *)keyword {
    [_cache setObject:value forKey:keyword];
}

@end
