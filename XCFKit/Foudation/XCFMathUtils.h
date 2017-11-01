//
//  XCFMathUtils.h
//  XCFKit
//
//  Created by Li Guoyin on 2017/10/31.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#ifndef XCFMathUtils_h
#define XCFMathUtils_h

#import <CoreGraphics/CoreGraphics.h>
#import <CoreFoundation/CoreFoundation.h>

#pragma mark - CGRect

extern CGPoint XCFGetRectCenterWithOffset(CGRect rect,CGPoint offset);

extern CGPoint XCFGetRectCenter(CGRect rect);

typedef enum : NSUInteger {
    XCFRectPositionTopLeft = 0,
    XCFRectPositionTopRight,
    XCFRectPositionBottomLeft,
    XCFRectPositionBottomRight,
    XCFRectPositionCenter
} XCFRectPosition;

extern CGRect XCFGetFrameForSizeInRect(CGSize size,CGRect rect,CGPoint offset,XCFRectPosition offsetPosition);

extern CGRect XCFCreateRectWithCenter(CGPoint center,CGSize size);

#endif //XCFMathUtils.h


