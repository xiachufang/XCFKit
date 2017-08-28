//
//  XCFTrieTree.m
//  XCFKit
//
//  Created by Li Guoyin on 2017/8/28.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import "XCFStringKeywordTransformer.h"
#import <set>

struct _XCFKeywordTransformerTrieNode;
typedef std::set<_XCFKeywordTransformerTrieNode> _TrieNodes;
typedef std::set<id> _DataProviders;

struct _XCFKeywordTransformerTrieNode {
    char value;
    bool isEnd;
    _TrieNodes _childNodes;
    _DataProviders _providers;
    
    bool operator == (const _XCFKeywordTransformerTrieNode &other) const {
        return value == other.value;
    }
    
    bool operator < (const _XCFKeywordTransformerTrieNode &other) const {
        return value < other.value;
    }
};
typedef struct _XCFKeywordTransformerTrieNode _XCFKeywordTransformerTrieNode;

@interface XCFStringKeywordTransformer ()

@property (nonatomic, assign) _XCFKeywordTransformerTrieNode rootNode;

@end

@implementation XCFStringKeywordTransformer

+ (instancetype) transformerWithDataProviders:(NSArray<id<XCFStringKeywordDataProvider>> *)dataProviders
{
    return [[self alloc] initWithDataProviders:dataProviders];
}

- (instancetype) initWithDataProviders:(NSArray<id<XCFStringKeywordDataProvider>> *)dataProviders
{
    NSParameterAssert(dataProviders.count > 0);
    self = [super init];
    if (self) {
        _rootNode.value = 0;
        _rootNode.isEnd = false;
        
        for (id<XCFStringKeywordDataProvider> provider in dataProviders) {
            NSArray<NSString *> *keywords = [provider keywords];
            for (NSString *keyword in keywords) {
                [self _insertKeyword:keyword
                               exist:NULL
                            provider:provider];
            }
        }
    }
    
    return self;
}

- (void) _insertKeyword:(NSString *)keyword exist:(BOOL *)exist provider:(id<XCFStringKeywordDataProvider>)provider
{
    NSParameterAssert(keyword.length > 0);
    
    const char* c_keyword = [keyword cStringUsingEncoding:NSUTF8StringEncoding];
    size_t length = 0;
    if (!c_keyword || (length = strlen(c_keyword)) == 0) {
        if (exist) *exist = NO;
        return;
    }
    
    BOOL _create_new_node = NO;
    
    _XCFKeywordTransformerTrieNode node = _rootNode;
    for (size_t i = 1; i <= length; i++) {
        const char value = c_keyword[i];
        
        _XCFKeywordTransformerTrieNode sub_node;
        sub_node.value = value;
        auto it = node._childNodes.find(sub_node);
        if (it == node._childNodes.end()) {
            node._childNodes.insert(sub_node);
            _create_new_node = YES;
        } else {
            sub_node = *it;
        }
        node = sub_node;
    }
    
    node.isEnd = true;
    if (provider) {
        node._providers.insert(provider);
    }
    
    if (exist) *exist = !_create_new_node;
}

@end

@implementation XCFStringKeywordTransformer (Transform)

- (NSString *) transformString:(NSString *)string
{
    return [self transformString:string dataCache:nil];
}

- (NSString *) transformString:(NSString *)string dataCache:(id<XCFStringKeywordDataCache>)cache
{
    NSParameterAssert(string);
    
    const char* c_string = [string cStringUsingEncoding:NSUTF8StringEncoding];
    if (!c_string) return nil;
    
    size_t origin_length = strlen(c_string);
    size_t container_length = origin_length * 2 + 1;
    char *container = (char*)malloc(container_length);
    if (!container) return string;
    
    
    return [NSString stringWithCString:container encoding:NSUTF8StringEncoding];
}

@end
