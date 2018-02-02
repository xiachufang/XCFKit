//
//  XCFRect.h
//  XCFKit
//
//  Created by Li Guoyin on 2017/10/31.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#ifndef XCFRect_h
#define XCFRect_h

#import <CoreGraphics/CoreGraphics.h>
#import <CoreFoundation/CoreFoundation.h>

#ifdef __cplusplus
extern "C"
{
#endif

    typedef enum : NSUInteger {
        XCFRectPositionTopLeft = 0,
        XCFRectPositionTopRight = 1,
        XCFRectPositionBottomLeft = 2,
        XCFRectPositionBottomRight = 3,
        XCFRectPositionCenter = 4,
    } XCFRectPosition;
    
    typedef XCFRectPosition XCFRectAnchorPoint;
    
    extern CGPoint XCFRectGetCenter(CGRect rect);
    extern CGPoint XCFRectGetCenterByOffset(CGRect rect,CGFloat x,CGFloat y);
    extern CGRect XCFRectGetFrameBySize(CGRect rect,CGSize size,XCFRectAnchorPoint anchor,CGFloat x,CGFloat y);
    extern CGRect XCFRectMake(CGSize size,CGPoint center);

#pragma mark - deprecated
    extern CGPoint XCFGetRectCenterWithOffset(CGRect rect,CGPoint offset);
    extern CGPoint XCFGetRectCenter(CGRect rect);
    extern CGRect XCFGetFrameForSizeInRect(CGSize size,CGRect rect,CGPoint offset,XCFRectPosition offsetPosition);
    extern CGRect XCFCreateRectWithCenter(CGPoint center,CGSize size);
    
#ifdef __cplusplus
}
#endif

#endif //XCFRect.h


