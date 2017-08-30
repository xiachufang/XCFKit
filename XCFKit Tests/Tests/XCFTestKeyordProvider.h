//
//  XCFTestKeyordProvider.h
//  Tests
//
//  Created by Guoyin Lee on 29/08/2017.
//

#import <Foundation/Foundation.h>
#import <XCFKit/XCFStringKeywordTransformer.h>

@interface XCFTestKeyordProvider : NSObject<XCFStringKeywordDataProvider>

@property (nonatomic, strong) NSArray<NSString *> *keywords;
@property (nonatomic, strong) NSString *value;

@end
