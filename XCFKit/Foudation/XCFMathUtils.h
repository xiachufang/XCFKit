//
//  XCFMathUtils.h
//  XCFKit
//
//  Created by Li Guoyin on 2017/10/31.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import <CoreFoundation/CoreFoundation.h>

#pragma mark - CGRect

extern inline CGPoint XCFGetRectCenterWithOffset(CGRect rect,CGPoint offset) {
    return
    (CGPoint){
        CGRectGetMidX(rect) + offset.x,
        CGRectGetMidY(rect) + offset.y
    };
}

extern inline CGPoint XCFGetRectCenter(CGRect rect) {
    return XCFGetRectCenterWithOffset(rect, CGPointZero);
}

typedef enum : NSUInteger {
    XCFRectPositionTopLeft = 0,
    XCFRectPositionTopRight,
    XCFRectPositionBottomLeft,
    XCFRectPositionBottomRight,
    XCFRectPositionCenter
} XCFRectPosition;

extern CGRect XCFGetFrameForSizeInRect(CGSize size,CGRect rect,CGPoint offset,XCFRectPosition offsetPosition);




