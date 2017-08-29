//
//  XCFTrieTree.m
//  XCFKit
//
//  Created by Li Guoyin on 2017/8/28.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import "XCFStringKeywordTransformer.h"
#import <set>
#import <string>

struct _XCFKeywordTransformerTrieNode;
struct _XCFkeywordDataProvider;
typedef std::set<_XCFKeywordTransformerTrieNode *> _TrieNodes;
typedef std::set<_XCFkeywordDataProvider *> _DataProviders;

struct _XCFkeywordDataProvider {
    id<XCFStringKeywordDataProvider> provider;
};

struct _XCFKeywordTransformerTrieNode {
    char value;
    bool isEnd;
    _TrieNodes *_childNodes;
    _DataProviders *_providers;
    
    bool operator == (const _XCFKeywordTransformerTrieNode &other) const {
        return value == other.value;
    }

    bool operator < (const _XCFKeywordTransformerTrieNode &other) const {
        return value < other.value;
    }
    
    _XCFKeywordTransformerTrieNode() {
        value = 0;
        isEnd = false;
        _childNodes = new _TrieNodes();
    }
    
    ~_XCFKeywordTransformerTrieNode() {
        delete _childNodes; _childNodes = NULL;
        delete _providers; _providers = NULL;
    }
};

FOUNDATION_STATIC_INLINE BOOL _isTrieNodeUniversalMatch(_XCFKeywordTransformerTrieNode *node) {
    return node && node->value == '*';
}

@interface XCFStringKeywordTransformer ()

@property (nonatomic, assign) _XCFKeywordTransformerTrieNode *rootNode;

@end

@implementation XCFStringKeywordTransformer

- (void) dealloc
{
    delete _rootNode;
}

+ (instancetype) transformerWithDataProviders:(NSArray<id<XCFStringKeywordDataProvider>> *)dataProviders
{
    return [[self alloc] initWithDataProviders:dataProviders];
}

- (instancetype) initWithDataProviders:(NSArray<id<XCFStringKeywordDataProvider>> *)dataProviders
{
    NSParameterAssert(dataProviders.count > 0);
    self = [super init];
    if (self) {
        _rootNode = new _XCFKeywordTransformerTrieNode();
        _matchCase = YES;
        _fallbackValue = @"";
        
        for (id<XCFStringKeywordDataProvider> provider in dataProviders) {
            NSArray<NSString *> *keywords = [provider keywords];
            for (NSString *keyword in keywords) {
                [self _insertKeyword:keyword
                            provider:provider];
            }
        }
    }
    
    return self;
}

- (instancetype) init
{
    return [self initWithDataProviders:@[]];
}

- (void) _insertKeyword:(NSString *)keyword provider:(id<XCFStringKeywordDataProvider>)provider
{
    NSParameterAssert(keyword.length > 0);
    
    const char* c_keyword = [keyword cStringUsingEncoding:NSUTF8StringEncoding];
    size_t length = 0;
    if (!c_keyword || (length = strlen(c_keyword)) == 0) {
        return;
    }
    
    BOOL _create_new_node = NO;
    
    _XCFKeywordTransformerTrieNode *node = _rootNode;
    for (size_t i = 1; i <= length; i++) {
        const char value = c_keyword[i];
        
        _XCFKeywordTransformerTrieNode *sub_node = NULL;
        for (_XCFKeywordTransformerTrieNode *__node : (*(node->_childNodes))) {
            if (value == __node->value) {
                sub_node = __node;
                break;
            }
        }
        
        if (!sub_node) {
            sub_node = new _XCFKeywordTransformerTrieNode();
            sub_node->value = value;
            (*(node->_childNodes)).insert(sub_node);
            
            _create_new_node = YES;
        }
        
        node = sub_node;
    }
    
    node->isEnd = true;
//    if (provider) {
//        if (!node->_providers) {
//            node->_providers = new _DataProviders();
//        }
//
//        _XCFkeywordDataProvider dataProvider = {provider};
//        (*(node->_providers)).insert(&dataProvider);
//    }
}

- (NSString *) _queryValueForKeyword:(NSString *)keyword
                           providers:(_DataProviders *)providers
                               cache:(id<XCFStringKeywordDataCache>)cache
{
//    NSParameterAssert(keyword && providers);
//    if (!keyword || !providers) return nil;
    
    NSString *value = [cache valueForKeyword:keyword];
    if (value) return value;
    
//    for (_XCFkeywordDataProvider *provider : *providers) {
//        id<XCFStringKeywordDataProvider> _p = provider->provider;
//        value = [_p valueForKeyword:keyword];
//        if (value) break;
//    }
    
    if (value) {
        [cache cacheValue:value forKeyword:keyword];
    }
    
    return value ?: self.fallbackValue;
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
    
    std::string origin_string = std::string(c_string);
    const size_t origin_length = origin_string.length();
    
    std::string mut_string = std::string();
    // expand string size
    if (mut_string.capacity() < origin_length * 2) {
        mut_string.reserve(origin_length * 2);
    }
    
    _XCFKeywordTransformerTrieNode *_base_node = self.rootNode;
    _XCFKeywordTransformerTrieNode *_step_node = NULL;
    
    size_t _match_pos = 0;
    size_t _match_length = 0;
    
    const BOOL match_case = self.matchCase;
    
    for (size_t idx = 0;;) {
        if (idx > origin_length) {
            if (_step_node) {
                _step_node = NULL;
                mut_string += origin_string[_match_pos];
                idx = _match_pos + 1;
                _match_pos = 0;
                _match_length = 0;
            } else {
                break;
            }
            
            continue;
        }
        
        const char c = origin_string[idx];
        char c_case = c;
        if (!match_case) {
            if (c_case >= 'a' && c_case <= 'z') c_case += ('A' - 'a');
            else if (c_case >= 'A' && c_case <= 'Z') c_case += ('a' - 'A');
        }
        
        _XCFKeywordTransformerTrieNode *match_node = NULL;
        _XCFKeywordTransformerTrieNode *query_node = _step_node ?: _base_node;
        for (_XCFKeywordTransformerTrieNode *node : *(query_node->_childNodes)) {
            if (_isTrieNodeUniversalMatch(node) || node->value == c || node->value == c_case) {
                match_node = node;
                break;
            }
        }
        
        if (_step_node) {
            if (match_node) {
                _step_node = match_node;
                _match_length += 1;
                idx += 1;
                
                if (_step_node->isEnd) {
                    // bingo
                    std::string result = origin_string.substr(_match_pos,_match_length);
                    NSString *keyword = [NSString stringWithUTF8String:result.c_str()];
                    NSString *value = [self _queryValueForKeyword:keyword
                                                        providers:_step_node->_providers
                                                            cache:cache];
                    if (value) {
                        mut_string += [value UTF8String];
                    }
                    
                    _step_node = NULL;
                    idx = _match_pos + _match_length;
                    _match_pos = 0;
                    _match_length = 0;
                }
            } else if (_isTrieNodeUniversalMatch(_step_node)) {
                _match_length += 1;
                idx += 1;
            } else {
                _step_node = NULL;
                idx = _match_pos + 1;
                mut_string += origin_string[_match_pos];
                _match_pos = 0;
                _match_length = 0;
            }
        } else {
            if (match_node) {
                _step_node = match_node;
                _match_pos = idx;
                _match_length = 1;
            } else {
                mut_string += c;
            }
            
            idx += 1;
        }
    }
    
    return [NSString stringWithUTF8String:mut_string.c_str()];
}

@end
