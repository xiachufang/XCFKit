//
//  XCFStringKeywordStandardCache.h
//  XCFKit iOS
//
//  Created by Guoyin Lee on 29/08/2017.
//  Copyright © 2017 XiaChuFang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol XCFStringKeywordDataCache <NSObject>

- (nullable NSString *)valueForKeyword:(NSString *)keyword;
- (void)cacheValue:(NSString *)value forKeyword:(NSString *)keyword;

@end

@interface XCFStringKeywordStandardCache : NSObject <XCFStringKeywordDataCache>

@end

NS_ASSUME_NONNULL_END
