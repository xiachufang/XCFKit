//
//  XCFTrieTree.m
//  XCFKit
//
//  Created by Li Guoyin on 2017/8/28.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#define XCFStringKeywordTransformerUseTrie 1

#import "XCFStringKeywordTransformer.h"

#if XCFStringKeywordTransformerUseTrie

#import <vector>
#import <string>
#import <map>

using namespace std;

struct _XCFKeywordTransformerNode {
    bool isEnd;
    char ch;
    vector<_XCFKeywordTransformerNode *> sub_nodes;
    _XCFKeywordTransformerNode *universal_sub_node;
};

FOUNDATION_STATIC_INLINE __unused BOOL _isTrieNodeUniversalMatch(_XCFKeywordTransformerNode *node)
{
    return node && node->ch == '*';
}

class _XCFKeywordTransformerTrie {
public:
    _XCFKeywordTransformerTrie() {
        head.ch = 0;
        head.isEnd = false;
    };
    ~_XCFKeywordTransformerTrie();
    _XCFKeywordTransformerNode* insert(string word);
    
    _XCFKeywordTransformerNode head;
    
protected:
    vector<_XCFKeywordTransformerNode *> all_nodes;
};

_XCFKeywordTransformerTrie::~_XCFKeywordTransformerTrie() {
    for (int i=0; i < all_nodes.size(); i++) {
        delete all_nodes[i];
    }
}

_XCFKeywordTransformerNode *_XCFKeywordTransformerTrie::insert(string word) {
    _XCFKeywordTransformerNode *leaf_node = NULL;
    _XCFKeywordTransformerNode *current_node = &head;
    vector<_XCFKeywordTransformerNode *> *current_tree = &head.sub_nodes;
    
    for (int i=0; i<word.length(); ++i) {
        char ch = word[i];
        if (ch == '\\') continue;
        
        leaf_node = NULL;
        
        size_t size = (*current_tree).size();
        size_t index = 0;
        for (index = 0;index < size; index++) {
            _XCFKeywordTransformerNode *node = (*current_tree)[index];
            if (ch == node->ch) {
                leaf_node = node;
                break;
            } else if (ch < node->ch) {
                break;
            }
        }
        
        if (!leaf_node) {
            _XCFKeywordTransformerNode *new_node = new _XCFKeywordTransformerNode();
            new_node->ch = ch;
            (*current_tree).insert(current_tree->begin() + index, new_node);
            leaf_node = new_node;
            
            all_nodes.push_back(new_node);
            
            if (_isTrieNodeUniversalMatch(new_node)) {
                current_node->universal_sub_node = new_node;
            }
        }
        
        current_tree = &leaf_node->sub_nodes;
        current_node = leaf_node;
    }
    
    if(leaf_node) leaf_node->isEnd = true;
    return leaf_node;
}

#endif // XCFStringKeywordTransformerUseTrie

@interface _XCFStringKeywordDataProviderWrapper : NSObject<XCFStringKeywordDataProvider>

+ (instancetype) wrapperDataProvider:(id<XCFStringKeywordDataProvider>)provider;
- (instancetype) initWithDataProvider:(id<XCFStringKeywordDataProvider>)provider NS_DESIGNATED_INITIALIZER;

@end

@implementation _XCFStringKeywordDataProviderWrapper
{
    NSValue *_wrapper;
}

+ (instancetype) wrapperDataProvider:(id<XCFStringKeywordDataProvider>)provider
{
    return [[self alloc] initWithDataProvider:provider];
}

- (instancetype) init
{
    return [self initWithDataProvider:nil];
}

- (instancetype) initWithDataProvider:(id<XCFStringKeywordDataProvider>)provider
{
    self = [super init];
    if (self) {
        _wrapper = [NSValue valueWithNonretainedObject:provider];
    }
    
    return self;
}

- (NSArray<NSString *> *) keywords
{
    id<XCFStringKeywordDataProvider> provider = _wrapper.nonretainedObjectValue;
    return [provider keywords] ?: @[];
}

- (NSString *) valueForKeyword:(NSString *)keyword
{
    id<XCFStringKeywordDataProvider> provider = _wrapper.nonretainedObjectValue;
    return [provider valueForKeyword:keyword];
}

- (BOOL) shouldHandleString:(NSString *)string
{
    id<XCFStringKeywordDataProvider> provider = _wrapper.nonretainedObjectValue;
    return [provider shouldHandleString:string];
}

@end

@interface XCFStringKeywordTransformer ()

@end

@implementation XCFStringKeywordTransformer
{
#if XCFStringKeywordTransformerUseTrie
    _XCFKeywordTransformerTrie _trie;
    map<_XCFKeywordTransformerNode*,vector<NSUInteger>> _providerIndexMap;
#endif // XCFStringKeywordTransformerUseTrie
    
    NSArray<id<XCFStringKeywordDataProvider>> *_dataProviders;
}

- (void) dealloc
{
#if XCFStringKeywordTransformerUseTrie
    _providerIndexMap.clear();
#endif // XCFStringKeywordTransformerUseTrie
}

+ (instancetype) transformerWithDataProviders:(NSArray<id<XCFStringKeywordDataProvider>> *)dataProviders
{
    return [[self alloc] initWithDataProviders:dataProviders];
}

+ (instancetype) transformerWithWeakDataProviders:(NSArray<id<XCFStringKeywordDataProvider>> *)dataProviders
{
    NSMutableArray<id<XCFStringKeywordDataProvider>> *_providers = [NSMutableArray arrayWithCapacity:dataProviders.count];
    for (id<XCFStringKeywordDataProvider> provider in dataProviders) {
        _XCFStringKeywordDataProviderWrapper *wrapper = [_XCFStringKeywordDataProviderWrapper wrapperDataProvider:provider];
        [_providers addObject:wrapper];
    }
    
    return [[self alloc] initWithDataProviders:_providers];
}

- (instancetype) initWithDataProviders:(NSArray<id<XCFStringKeywordDataProvider>> *)dataProviders
{
    NSParameterAssert(dataProviders.count > 0);
    self = [super init];
    if (self) {
        _matchCase = YES;
        _fallbackValue = @"";
        _dataProviders = [dataProviders copy];
        
#if XCFStringKeywordTransformerUseTrie
        [_dataProviders enumerateObjectsUsingBlock:^(id<XCFStringKeywordDataProvider> obj, NSUInteger idx, BOOL *stop) {
            NSArray *keywords = [obj keywords];
            for (NSString *keyword in keywords) {
                [self _insertKeyword:keyword providerIndex:idx];
            }
        }];
#endif // XCFStringKeywordTransformerUseTrie
    }
    
    return self;
}

- (instancetype) init
{
    return [self initWithDataProviders:@[]];
}

#if XCFStringKeywordTransformerUseTrie

- (void) _insertKeyword:(NSString *)keyword providerIndex:(NSUInteger)providerIndex
{
    NSParameterAssert(keyword.length > 0);
    
    const char* c_keyword = [keyword cStringUsingEncoding:NSUTF8StringEncoding];
    size_t length = 0;
    if (!c_keyword || (length = strlen(c_keyword)) == 0) {
        return;
    }
    
    _XCFKeywordTransformerNode *node = _trie.insert(string(c_keyword));
    
    NSParameterAssert(node);
    
    if (node) {
        map<_XCFKeywordTransformerNode*,vector<NSUInteger>>::iterator it;
        if ((it = _providerIndexMap.find(node)) != _providerIndexMap.end()) {
            it->second.push_back(providerIndex);
        } else {
            vector<NSUInteger> list;
            list.push_back(providerIndex);
            _providerIndexMap[node] = list;
        }
    }
}

#endif

- (NSString *) _queryValueForKeyword:(NSString *)keyword
                           providers:(NSArray<id<XCFStringKeywordDataProvider>> *)providers
                               cache:(id<XCFStringKeywordDataCache>)cache
{
    NSParameterAssert(keyword && providers.count > 0);
    
    NSString *value = [cache valueForKeyword:keyword];
    if (value) return value;
    
    for (id<XCFStringKeywordDataProvider> provider in providers) {
        value = [provider valueForKeyword:keyword];
        if (value) break;
    }
    
    if (value) {
        [cache cacheValue:value forKeyword:keyword];
    }
    
    return value ?: self.fallbackValue;
}

@end

#if XCFStringKeywordTransformerUseTrie

static _XCFKeywordTransformerNode * _findNodeWithRange(vector<_XCFKeywordTransformerNode *> *nodes, char ch, int l, int r) {
    if (l > r || !nodes) return NULL;
    int pos = l + (r - l) / 2;
    _XCFKeywordTransformerNode *node = (*nodes)[pos];
    if (ch == node->ch) return node;
    else if (ch > node->ch) return _findNodeWithRange(nodes, ch, pos+1, r);
    else return _findNodeWithRange(nodes, ch, l, pos - 1);
}

static _XCFKeywordTransformerNode * _findNode(vector<_XCFKeywordTransformerNode *> *nodes, char ch) {
    if (!nodes) return NULL;
    
    _XCFKeywordTransformerNode *node = _findNodeWithRange(nodes, ch, 0, ((int)(*nodes).size()) - 1);
    return node;
}

static BOOL _searchStringInTrie(const _XCFKeywordTransformerTrie *trie,const string *string,size_t *base,size_t *match_length,_XCFKeywordTransformerNode **node,const BOOL match_case) {
    if (trie == NULL || string == NULL || base == NULL) return NO;
    
    const size_t string_length = string->length();
    size_t pos = *base;
    
    vector<_XCFKeywordTransformerNode *> sub_nodes = trie->head.sub_nodes;
    _XCFKeywordTransformerNode *match_node = NULL;
    _XCFKeywordTransformerNode *fallbackNode = trie->head.universal_sub_node;
    
    while (pos < string_length) {
        const char c = string->at(pos);
        
        match_node = _findNode(&sub_nodes, c);
        if (!match_node && !match_case) {
            char c_case = c;
            if (c_case >= 'a' && c_case <= 'z') c_case += ('A' - 'a');
            else if (c_case >= 'A' && c_case <= 'Z') c_case += ('a' - 'A');
            
            if (c_case != c) {
                match_node = _findNode(&sub_nodes, c_case);
            }
        }
        
        if (!match_node) {
            match_node = fallbackNode;
        }
        
        if (match_node) {
            pos += 1;
            
            if (match_node->isEnd) {
                if (match_length) *match_length = pos - *base;
                if (node) *node = match_node;
                return YES;
            } else {
                sub_nodes = match_node->sub_nodes;
                if (match_node->universal_sub_node) {
                    fallbackNode = match_node->universal_sub_node;
                }
            }
        } else {
            if (pos == *base) {
                pos += 1;
                *base += 1;
            } else {
                break;
            }
        }
    }
    
    *base += 1;
    if (match_length) *match_length = 0;
    return NO;
}

#endif // XCFStringKeywordTransformerUseTrie

@implementation XCFStringKeywordTransformer (Transform)

- (NSString *) transformString:(NSString *)string
{
    return [self transformString:string dataCache:nil];
}

#if XCFStringKeywordTransformerUseTrie

- (NSString *) transformString:(NSString *)string dataCache:(id<XCFStringKeywordDataCache>)cache
{
    NSParameterAssert(string);
    
    BOOL shouldHandle = NO;
    for (id<XCFStringKeywordDataProvider> provider in _dataProviders) {
        shouldHandle = [provider shouldHandleString:string];
        if (shouldHandle) break;
    }
    
    if (!shouldHandle) return [string copy];
    
    const char* c_string = [string cStringUsingEncoding:NSUTF8StringEncoding];
    if (!c_string) return @"";
    
    std::string origin_string = std::string(c_string);
    const size_t origin_length = origin_string.length();
    
    std::string mut_string = std::string();
    // expand string size
    if (mut_string.capacity() < origin_length * 1.5) {
        mut_string.reserve(origin_length * 1.5);
    }
    
    const BOOL match_case = self.matchCase;
    
    for (size_t pos = 0; pos < origin_length;) {
        size_t match_base = pos;
        size_t match_length = 0;
        _XCFKeywordTransformerNode *match_node;
        if (_searchStringInTrie(&_trie, &origin_string, &match_base, &match_length,&match_node, match_case) && match_length > 0 && match_node) {
            if(match_base > pos) mut_string.append(origin_string.substr(pos,match_base-pos));
            std::string match_string = origin_string.substr(match_base,match_length);
            NSString *keyword = [NSString stringWithUTF8String:match_string.c_str()];
            NSMutableArray<id<XCFStringKeywordDataProvider>> *providers = [NSMutableArray new];
            
            vector<NSUInteger> indexes = _providerIndexMap[match_node];
            for (NSUInteger index : indexes) {
                id<XCFStringKeywordDataProvider> provider = _dataProviders[index];
                [providers addObject:provider];
            }
            
            NSString *value = [self _queryValueForKeyword:keyword
                                                providers:providers
                                                    cache:cache];
            if (value) {
                mut_string.append([value UTF8String]);
            } else {
                mut_string.append(match_string);
            }
            
            pos = match_base + match_length;
        } else {
            mut_string.append(origin_string.substr(pos,match_base-pos));
            pos = match_base;
        }
    }
    
    return [NSString stringWithUTF8String:mut_string.c_str()];
}

- (NSArray<NSTextCheckingResult *> *) searchResultsFromString:(NSString *)string
{
    NSParameterAssert(string);
    
    const char* c_string = [string cStringUsingEncoding:NSUTF8StringEncoding];
    if (!c_string) return @[];
    
    std::string origin_string = std::string(c_string);
    const size_t origin_length = origin_string.length();
    
    const BOOL match_case = self.matchCase;
    
    NSMutableArray<NSTextCheckingResult *> *results = [NSMutableArray new];
    
    for (size_t pos = 0; pos < origin_length;) {
        size_t match_base = pos;
        size_t match_length = 0;
        _XCFKeywordTransformerNode *match_node;
        if (_searchStringInTrie(&_trie, &origin_string, &match_base, &match_length,&match_node, match_case) && match_length > 0 && match_node) {
            std::string match_string = origin_string.substr(match_base,match_length);
            NSString *keyword = [NSString stringWithUTF8String:match_string.c_str()];
            NSRange range = NSMakeRange(match_base, match_length);
            NSTextCheckingResult *result = [NSTextCheckingResult replacementCheckingResultWithRange:range replacementString:keyword];
            [results addObject:result];
            
            pos = match_base + match_length;
        } else {
            pos = match_base;
        }
    }

    return [results copy];
}

#else

- (NSString *) transformString:(NSString *)string dataCache:(id<XCFStringKeywordDataCache>)cache
{
    if (string.length == 0) return @"";
    
    const BOOL match_case = self.matchCase;
    
    NSMutableString *mutableString = [string mutableCopy];
    NSCharacterSet *regexSet = [NSCharacterSet characterSetWithCharactersInString:@"*?|.^$"];
    NSRegularExpressionOptions regexOption = NSRegularExpressionDotMatchesLineSeparators | NSRegularExpressionAnchorsMatchLines;
    if (!match_case) regexOption |= NSRegularExpressionCaseInsensitive;
    for (id<XCFStringKeywordDataProvider> provider in _dataProviders) {
        if (![provider shouldHandleString:mutableString]) continue;
        
        NSArray<NSString *> *keywords = [provider keywords];
        for (NSString *keyword in keywords) {
            if (keyword.length == 0) continue;
            NSRange range = NSMakeRange(0, mutableString.length);
            NSRegularExpression *ex = nil;
            if ([keyword rangeOfCharacterFromSet:regexSet].location != NSNotFound &&
                (ex = [NSRegularExpression regularExpressionWithPattern:keyword
                                                                options:regexOption
                                                                  error:nil])) {
                NSString *searchString = [mutableString copy];
                NSArray<NSTextCheckingResult *> *results = [ex matchesInString:searchString options:0 range:range];
                for (NSTextCheckingResult *result in results) {
                    NSRange match_range = result.range;
                    NSString *match = [searchString substringWithRange:match_range];
                    NSString *value = [self _queryValueForKeyword:match
                                                        providers:@[provider]
                                                            cache:cache];
                    if (value) {
                        [mutableString replaceOccurrencesOfString:match
                                                       withString:value
                                                          options:!match_case ? NSCaseInsensitiveSearch : 0
                                                            range:NSMakeRange(0, mutableString.length)];
                    }
                }
            } else {
                NSString *value = [self _queryValueForKeyword:keyword
                                                    providers:@[provider]
                                                        cache:cache];
                if (value) {
                    [mutableString replaceOccurrencesOfString:keyword
                                                   withString:value
                                                      options:!match_case ? NSCaseInsensitiveSearch : 0
                                                        range:range];
                }
            }
        }
    }
    
    return [mutableString copy];
}

- (NSArray<NSTextCheckingResult *> *) searchResultsFromString:(NSString *)string
{
    if (string.length == 0) return @[];
    const BOOL match_case = self.matchCase;
    
    NSCharacterSet *regexSet = [NSCharacterSet characterSetWithCharactersInString:@"*?|.^$"];
    NSRegularExpressionOptions regexOption = NSRegularExpressionDotMatchesLineSeparators | NSRegularExpressionAnchorsMatchLines;
    if (!match_case) regexOption |= NSRegularExpressionCaseInsensitive;
    
    NSMutableArray<NSTextCheckingResult *> *finalResults = [NSMutableArray new];
    for (id<XCFStringKeywordDataProvider> provider in _dataProviders) {
        if (![provider shouldHandleString:string]) continue;
        
        NSArray<NSString *> *keywords = [provider keywords];
        for (NSString *keyword in keywords) {
            if (keyword.length == 0) continue;
            NSRange range = NSMakeRange(0, string.length);
            NSRegularExpression *ex = nil;
            if ([keyword rangeOfCharacterFromSet:regexSet].location != NSNotFound) {
                ex = [NSRegularExpression regularExpressionWithPattern:keyword
                                                                options:regexOption
                                                                 error:nil];
            }
            
            if (!ex) {
                ex = [NSRegularExpression regularExpressionWithPattern:keyword
                                                               options:regexOption | NSRegularExpressionIgnoreMetacharacters
                                                                 error:nil];
            }
            
            NSArray<NSTextCheckingResult *> *results = [ex matchesInString:string options:0 range:range];
            for (NSTextCheckingResult *result in results) {
                NSRange match_range = result.range;
                NSString *match = [string substringWithRange:match_range];
                
                NSTextCheckingResult *__result = [NSTextCheckingResult replacementCheckingResultWithRange:match_range replacementString:match];
                [finalResults addObject:__result];
            }
        }
    }
    
    return [finalResults copy];
}

#endif //XCFStringKeywordTransformerUseTrie

@end

#undef XCFStringKeywordTransformerUseTrie
