//
//  XCFRect.m
//  XCFKit
//
//  Created by Li Guoyin on 2017/10/31.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import "XCFRect.h"

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

CGPoint XCFRectGetCenter(CGRect rect) {
    return XCFRectGetCenterByOffset(rect, 0, 0);
}

CGPoint XCFRectGetCenterByOffset(CGRect rect,CGFloat x,CGFloat y) {
    return (CGPoint) {
        CGRectGetMidX(rect) + x,
        CGRectGetMidY(rect) + y
    };
}

CGRect XCFRectGetFrameBySize(CGRect rect,CGSize size,XCFRectAnchorPoint anchor,CGFloat x,CGFloat y) {
    _XCFOffsetPosition position_x = _offsetPositions[anchor * 2];
    _XCFOffsetPosition position_y = _offsetPositions[anchor * 2 + 1];
    
    CGPoint origin;
    origin.x = rect.origin.x + position_x.a * rect.size.width + position_x.b * x + position_x.c * size.width;
    origin.y = rect.origin.y + position_y.a * rect.size.height + position_y.b * y + position_y.c * size.height;
    return (CGRect){origin,size};
}

CGRect XCFRectMake(CGSize size,CGPoint center) {
    CGPoint origin;
    origin.x = center.x - size.width / 2;
    origin.y = center.y - size.height / 2;
    return (CGRect){origin,size};
}

#pragma mark - deprecated

CGPoint XCFGetRectCenterWithOffset(CGRect rect,CGPoint offset) {
    return XCFRectGetCenterByOffset(rect, offset.x, offset.y);
}

CGPoint XCFGetRectCenter(CGRect rect) {
    return XCFRectGetCenter(rect);
}

CGRect XCFGetFrameForSizeInRect(CGSize size,CGRect rect,CGPoint offset,XCFRectPosition offsetPosition) {
    return XCFRectGetFrameBySize(rect, size, offsetPosition, offset.x, offset.y);
}

CGRect XCFCreateRectWithCenter(CGPoint center,CGSize size) {
    return XCFRectMake(size, center);
}
