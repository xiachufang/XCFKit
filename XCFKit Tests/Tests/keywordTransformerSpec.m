//
//  keywordTransformerSpec.m
//  XCFKit Tests
//
//  Created by Guoyin Lee on 29/08/2017.
//  Copyright 2017 ___ORGANIZATIONNAME___. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import <XCFKit/XCFStringKeywordTransformer.h>
#import <XCFKit/XCFStringKeywordStandardCache.h>
#import "XCFTestKeyordProvider.h"

SPEC_BEGIN(keywordTransformerSpec)

describe(@"keywordTransformer", ^{
    let(transformer, ^id{
        XCFTestKeyordProvider *provider_1 = [XCFTestKeyordProvider new];
        provider_1.keywords = @[@"{IDFA}",@"{VERSION}"];
        provider_1.value = @"provider_1";
        XCFTestKeyordProvider *provider_2 = [XCFTestKeyordProvider new];
        provider_1.keywords = @[@"{WIDTH}",@"{HEIGHT}"];
        provider_1.value = @"provider_2";
        XCFTestKeyordProvider *provider_3 = [XCFTestKeyordProvider new];
        provider_1.keywords = @[@"{FLAG}",@"{NAME}"];
        provider_1.value = @"provider_3";
        XCFTestKeyordProvider *provider_4 = [XCFTestKeyordProvider new];
        provider_1.keywords = @[@"{*}"];
        provider_1.value = @"provider_4";
        XCFStringKeywordTransformer *t = [XCFStringKeywordTransformer transformerWithDataProviders:@[provider_1,provider_2,provider_3,provider_4]];
        return t;
    });
    
    context(@"transform", ^{
        it(@"shoud transform string", ^{
            
        });
    });
});

SPEC_END
