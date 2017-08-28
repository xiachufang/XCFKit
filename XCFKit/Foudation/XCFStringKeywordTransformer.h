//
//  XCFTrieTree.h
//  XCFKit
//
//  Created by Li Guoyin on 2017/8/28.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol XCFStringKeywordDataProvider <NSObject>

- (NSArray<NSString *> *) keywords;
- (nullable NSString *) valueForKeyword:(NSString *)keyword;

@end

@protocol XCFStringKeywordDataCache <NSObject>

- (nullable NSString *) valueForKeyword:(NSString *)keyword;
- (void) cacheValue:(NSString *)value forKeyword:(NSString *)keyword;

@end

@interface XCFStringKeywordTransformer : NSObject

- (instancetype) initWithDataProviders:(NSArray<id<XCFStringKeywordDataProvider>> *)dataProviders;

+ (instancetype) transformerWithDataProviders:(NSArray<id<XCFStringKeywordDataProvider>> *)dataProviders;

@property (nonatomic, assign) BOOL matchCase; // default is YES;

@end

@interface XCFStringKeywordTransformer (Transform)

- (NSString *) transformString:(NSString *)string;
- (NSString *) transformString:(NSString *)string dataCache:(nullable id<XCFStringKeywordDataCache>)cache;

@end

NS_ASSUME_NONNULL_END
