//
//  XCFMathUtils.m
//  XCFKit
//
//  Created by Li Guoyin on 2017/10/31.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import "XCFMathUtils.h"

typedef struct {
    CGFloat a;
    CGFloat b;
    CGFloat c;
} _XCFOffsetPosition;

static _XCFOffsetPosition _offsetPositions[] = {
    {0,1,0},
    {0,1,0},
    {1,-1,-1},
    {0,1,0},
    {0,1,0},
    {1,-1,-1},
    {1,-1,-1},
    {1,-1,-1},
    {0.5,1,-0.5},
    {0.5,1,-0.5}
};

CGPoint XCFGetRectCenterWithOffset(CGRect rect,CGPoint offset) {
    return
    (CGPoint){
        CGRectGetMidX(rect) + offset.x,
        CGRectGetMidY(rect) + offset.y
    };
}

CGPoint XCFGetRectCenter(CGRect rect) {
    return XCFGetRectCenterWithOffset(rect, CGPointZero);
}

CGRect XCFGetFrameForSizeInRect(CGSize size,CGRect rect,CGPoint offset,XCFRectPosition offsetPosition) {
    _XCFOffsetPosition position_x = _offsetPositions[offsetPosition * 2];
    _XCFOffsetPosition position_y = _offsetPositions[offsetPosition * 2 + 1];
    
    CGPoint origin;
    origin.x = rect.origin.x + position_x.a * rect.size.width + position_x.b * offset.x + position_x.c * size.width;
    origin.y = rect.origin.y + position_y.a * rect.size.height + position_y.b * offset.y + position_y.c * size.height;
    return (CGRect){origin,size};
}

CGRect XCFCreateRectWithCenter(CGPoint center,CGSize size)
{
    CGPoint origin;
    origin.x = center.x - size.width / 2;
    origin.y = center.y - size.height / 2;
    return (CGRect){origin,size};
}
