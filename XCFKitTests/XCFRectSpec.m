//
//  XCFRectSpec.m
//  XCFKit
//
//  Created by Li Guoyin on 2018/1/24.
//  Copyright 2018年 xiachufang. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "XCFRect.h"

SPEC_BEGIN(XCFRectSpec)

describe(@"XCFRect", ^{
    context(@"should get correct result", ^{
        it(@"get center", ^{
            CGRect rect = CGRectMake(20, 40, 100, 80);
            CGPoint center = XCFRectGetCenter(rect);
            [[theValue(center.x) should] equal:@70];
            [[theValue(center.y) should] equal:@80];
            
            center = XCFRectGetCenterByOffset(rect, 10, -10);
            [[theValue(center.x) should] equal:@80];
            [[theValue(center.y) should] equal:@70];
        });
        
        it(@"make rect at top left", ^{
            CGRect rect = CGRectMake(20, 40, 100, 80);
            XCFRectAnchorPoint anchor = XCFRectPositionTopLeft;
            CGPoint offsets[] = {{0,0},{10,10},{-10,10},{-10,-10}};
            NSInteger offsetCount = sizeof(offsets) / sizeof(CGPoint);
            CGPoint origins[] = {{20,40},{30,50},{10,50},{10,30}};
            NSInteger originCount = sizeof(origins) / sizeof(CGPoint);
            [[theValue(offsetCount) should] equal:@(originCount)];
            CGSize size = {20, 20};
            
            for (NSInteger idx = 0;idx < originCount;idx ++) {
                CGPoint offset = offsets[idx];
                CGRect result = XCFRectGetFrameBySize(rect, size, anchor, offset.x, offset.y);
                [[theValue(result.size) should] equal:theValue(size)];
                [[theValue(result.origin) should] equal:theValue(origins[idx])];
            }
        });
        
        it(@"make rect at top right", ^{
            CGRect rect = CGRectMake(20, 40, 100, 80);
            XCFRectAnchorPoint anchor = XCFRectPositionTopRight;
            CGPoint offsets[] = {{0,0},{10,10},{-10,10},{-10,-10}};
            NSInteger offsetCount = sizeof(offsets) / sizeof(CGPoint);
            CGPoint origins[] = {{100,40},{90,50},{110,50},{110,30}};
            NSInteger originCount = sizeof(origins) / sizeof(CGPoint);
            [[theValue(offsetCount) should] equal:@(originCount)];
            CGSize size = {20, 20};
            
            for (NSInteger idx = 0;idx < originCount;idx ++) {
                CGPoint offset = offsets[idx];
                CGRect result = XCFRectGetFrameBySize(rect, size, anchor, offset.x, offset.y);
                [[theValue(result.size) should] equal:theValue(size)];
                [[theValue(result.origin) should] equal:theValue(origins[idx])];
            }
        });
    });
});

SPEC_END
