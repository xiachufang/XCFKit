//
//  XCFTrieTree.m
//  XCFKit
//
//  Created by Li Guoyin on 2017/8/28.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#define XCFStringKeywordTransformerUseTrie 0

#import "XCFStringKeywordTransformer.h"

#if XCFStringKeywordTransformerUseTrie

#import <vector>
#import <map>
#import <list>
#import <string>

using namespace std;

struct _XCFKeywordTransformerNode {
    char ch;
    bool isEnd;
    map<char,_XCFKeywordTransformerNode *> sub_nodes;
};

FOUNDATION_STATIC_INLINE BOOL _isTrieNodeUniversalMatch(_XCFKeywordTransformerNode *node) {
    return node && node->ch == '*';
}

class _XCFKeywordTransformerTrie {
public:
    _XCFKeywordTransformerTrie() {
        head.ch = -1;
        head.isEnd = false;
    }
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
    if (word.length() == 0) return NULL;
    
    _XCFKeywordTransformerNode *leaf_node = &head;
    map<char, _XCFKeywordTransformerNode*> *current_tree = &leaf_node->sub_nodes;
    map<char, _XCFKeywordTransformerNode*>::iterator it;
    
    for (int i=0; i<word.length(); ++i) {
        char ch = word[i];
        
        if ((it = current_tree->find(ch)) != current_tree->end()) {
            leaf_node = it->second;
        } else {
            _XCFKeywordTransformerNode* new_node = new _XCFKeywordTransformerNode();
            new_node->ch = ch;
            (*current_tree)[ch] = new_node;
            leaf_node = new_node;
            
            all_nodes.push_back(new_node);
        }
        
        current_tree = &leaf_node->sub_nodes;
    }
    
    leaf_node->isEnd = true;
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

@end

@interface XCFStringKeywordTransformer ()

@end

@implementation XCFStringKeywordTransformer
{
#if XCFStringKeywordTransformerUseTrie
    _XCFKeywordTransformerTrie _trie;
    map<_XCFKeywordTransformerNode*,list<NSUInteger>> _providerIndexMap;
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

- (instancetype) initWithDataProviders:(NSArray<id<XCFStringKeywordDataProvider>> *)dataProviders
{
    NSParameterAssert(dataProviders.count > 0);
    self = [super init];
    if (self) {
        _matchCase = NO;
        _fallbackValue = @"";
        NSMutableArray<id<XCFStringKeywordDataProvider>> *_providers = [NSMutableArray arrayWithCapacity:dataProviders.count];
        for (id<XCFStringKeywordDataProvider> provider in dataProviders) {
            _XCFStringKeywordDataProviderWrapper *wrapper = [_XCFStringKeywordDataProviderWrapper wrapperDataProvider:provider];
            [_providers addObject:wrapper];
        }
        _dataProviders = [_providers copy];
        
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
    map<_XCFKeywordTransformerNode*,list<NSUInteger>>::iterator it;
    if ((it = _providerIndexMap.find(node)) != _providerIndexMap.end()) {
        it->second.push_back(providerIndex);
    } else {
        list<NSUInteger> list;
        list.push_back(providerIndex);
        _providerIndexMap[node] = list;
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

static BOOL _searchStringInTrie(const _XCFKeywordTransformerTrie *trie,const std::string *string,size_t base,size_t *match_length,_XCFKeywordTransformerNode **node,const BOOL match_case) {
    if (trie == NULL || string == NULL) return NO;
    
    const size_t string_length = string->length();
    size_t pos = base;
    
    map<char,_XCFKeywordTransformerNode *> sub_nodes = trie->head.sub_nodes;
    map<char,_XCFKeywordTransformerNode *>::iterator it;
    BOOL match_universal = NO;
    
    while (pos < string_length) {
        const char c = string->at(pos);
        
        it = sub_nodes.find(c);
        if (it == sub_nodes.end()) {
            it = sub_nodes.find('*');
        }
        if (it == sub_nodes.end() && !match_case) {
            char c_case = c;
            if (c_case >= 'a' && c_case <= 'z') c_case += ('A' - 'a');
            else if (c_case >= 'A' && c_case <= 'Z') c_case += ('a' - 'A');
            
            it = sub_nodes.find(c_case);
        }
        
        _XCFKeywordTransformerNode *match_node = it->second;
        
        if (it != sub_nodes.end() && match_node->isEnd) {
            pos += 1;
            if (match_length) *match_length = pos - base;
            if (node) *node = match_node;
            return YES;
        } else if (it != sub_nodes.end()) {
            match_universal = _isTrieNodeUniversalMatch(match_node);
            sub_nodes = match_node->sub_nodes;
            pos += 1;
        } else if (match_universal) {
            pos += 1;
        } else {
            break;
        }
    }
    
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
    
    const char* c_string = [string cStringUsingEncoding:NSUTF8StringEncoding];
    if (!c_string) return nil;
    
    std::string origin_string = std::string(c_string);
    const size_t origin_length = origin_string.length();
    
    std::string mut_string = std::string();
    // expand string size
    if (mut_string.capacity() < origin_length * 2) {
        mut_string.reserve(origin_length * 2);
    }
    
    const BOOL match_case = self.matchCase;
    
    for (size_t pos = 0; pos < origin_length;) {
        size_t match_length = 0;
        _XCFKeywordTransformerNode *match_node;
        if (_searchStringInTrie(&_trie, &origin_string, pos, &match_length,&match_node, match_case) && match_length > 0 && match_node) {
            std::string match_string = origin_string.substr(pos,match_length);
            NSString *keyword = [NSString stringWithUTF8String:match_string.c_str()];
            NSMutableArray<id<XCFStringKeywordDataProvider>> *providers = [NSMutableArray new];
            
            list<NSUInteger> indexes = _providerIndexMap[match_node];
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
            
            pos += match_length;
        } else {
            mut_string.push_back(origin_string[pos]);
            pos += 1;
        }
    }
    
    return [NSString stringWithUTF8String:mut_string.c_str()];
}

#else

- (NSString *) transformString:(NSString *)string dataCache:(id<XCFStringKeywordDataCache>)cache
{
    if (string.length == 0) return @"";
    
    const BOOL match_case = self.matchCase;
    
    NSMutableString *mutableString = [string mutableCopy];
    NSCharacterSet *regexSet = [NSCharacterSet characterSetWithCharactersInString:@"*?|."];
    for (id<XCFStringKeywordDataProvider> provider in _dataProviders) {
        NSArray<NSString *> *keywords = [provider keywords];
        for (NSString *keyword in keywords) {
            if (keyword.length == 0) continue;
                NSRange range = NSMakeRange(0, mutableString.length);
                if ([keyword rangeOfCharacterFromSet:regexSet].location != NSNotFound) {
                    NSString *pattern = [keyword stringByReplacingOccurrencesOfString:@"*" withString:@".*"];
                    NSError *error = nil;
                    NSRegularExpression *ex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                        options:!match_case ? NSRegularExpressionCaseInsensitive : 0
                                                                                          error:&error];
                    if (ex) {
                        NSString *searchString = [mutableString copy];
                        [ex enumerateMatchesInString:searchString options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
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
                        }];
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

#endif //XCFStringKeywordTransformerUseTrie

@end
