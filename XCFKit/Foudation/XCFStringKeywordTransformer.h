//
//  XCFTrieTree.h
//  XCFKit
//
//  Created by Li Guoyin on 2017/8/28.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XCFStringKeywordStandardCache.h"

NS_ASSUME_NONNULL_BEGIN

@protocol XCFStringKeywordDataProvider <NSObject>

- (NSArray<NSString *> *) keywords;
- (nullable NSString *) valueForKeyword:(NSString *)keyword;

- (BOOL) shouldHandleString:(NSString *)string;

@end

@interface XCFStringKeywordTransformer : NSObject

- (instancetype) initWithDataProviders:(NSArray<id<XCFStringKeywordDataProvider>> *)dataProviders NS_DESIGNATED_INITIALIZER;

+ (instancetype) transformerWithDataProviders:(NSArray<id<XCFStringKeywordDataProvider>> *)dataProviders;
+ (instancetype) transformerWithWeakDataProviders:(NSArray<id<XCFStringKeywordDataProvider>> *)dataProviders;

@property (nonatomic, assign) BOOL matchCase; // default is YES;
@property (nonatomic, copy, nullable) NSString *fallbackValue; // default is empty string

@end

@interface XCFStringKeywordTransformer (Transform)

- (NSString *) transformString:(NSString *)string;
- (NSString *) transformString:(NSString *)string dataCache:(nullable id<XCFStringKeywordDataCache>)cache;

- (NSArray<NSTextCheckingResult *> *) searchResultsFromString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
