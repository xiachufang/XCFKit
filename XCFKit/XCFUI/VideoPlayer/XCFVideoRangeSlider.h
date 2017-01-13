//
//  XCFVideoRangerSlider.h
//  XCFKit
//
//  Created by Li Guoyin on 2017/1/4.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "XCFVideoRange.h"

@class AVAsset;

/*
 *  用来选择视频片段的选择器，通过 UIControlEventValueChanged 事件向订阅者发送消息
 *
 */

@interface XCFVideoRangeSlider : UIControl

@property (nonatomic, assign) XCFVideoRange currentRange; // default is XCFVideoRangeEmpty , set 方法暂不可用

@property (nonatomic, assign, readonly) NSTimeInterval videoLength;

// 在 load 之前，`videoPath` 为 nil，`videoLength` 为 0
// asset 在初始化的时候需要设置 AVURLAssetPreferPreciseDurationAndTimingKey 为 1 不然取不到准确的时间
- (void) loadVideoFramesWithVideoAsset:(AVAsset *)asset;

@property (nonatomic, assign) NSTimeInterval maximumTrimLength; // default is 15s, must be positive
@property (nonatomic, assign) NSTimeInterval minimumTrimLength; // default is 03s, must be positive

@end
