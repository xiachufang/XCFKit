//
//  XCFVideoLoadProgressView.h
//  XCFKit
//
//  Created by Li Guoyin on 2017/1/18.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    XCFVideoLoadStatusPlay,
    XCFVideoLoadStatusLoading,
    XCFVideoLoadStatusProgress,
} XCFVideoLoadStatus;

@interface XCFVideoLoadProgressView : UIView

@property (nonatomic, assign) XCFVideoLoadStatus status;
@property (nonatomic, assign) CGFloat progress; // progress is [0..1]

@end
