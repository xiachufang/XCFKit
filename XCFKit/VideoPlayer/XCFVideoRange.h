//
//  XCFVideoRange.h
//  XCFKit
//
//  Created by Li Guoyin on 2017/1/13.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#ifndef XCFVideoRange_h
#define XCFVideoRange_h

struct XCFVideoRange {
    NSTimeInterval location;
    NSTimeInterval length;
};

typedef struct XCFVideoRange XCFVideoRange;

#define XCFVideoRangeEmpty ((XCFVideoRange){0,0})

static inline NSTimeInterval
XCFVideoRangeGetEnd(XCFVideoRange range)
{
    return range.location + range.length;
}

static inline BOOL
XCFVideoRangeEqualToRange(XCFVideoRange range1,XCFVideoRange range2)
{
    return range1.location == range2.location && range1.length == range2.length;
}

static inline XCFVideoRange
XCFVideoRangeMake(NSTimeInterval start,NSTimeInterval end)
{
    return (XCFVideoRange){start,MAX(0, end - start)};
}

#endif /* XCFVideoRange_h */
