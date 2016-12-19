//
//  XCFAVPlayerView.h
//  XCFKit
//
//  Created by Li Guoyin on 2016/12/19.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XCFVideoPlayerControlProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class XCFAVPlayerView;

@protocol XCFAVPlayerViewDelegate <NSObject>

@optional

- (void) avPlayerViewDidPlayToEnd:(XCFAVPlayerView *)playerView;
- (void) avPlayerViewDidUpgradeProgress:(XCFAVPlayerView *)playerView;

@end

@interface XCFAVPlayerView : UIView<XCFVideoPlayerControlProtocol>

- (void) prepareToPlayVideoAtPath:(NSString *)videoPath
                       completion:(void (^)(BOOL completion,NSError *_Nullable error))completion;

@property (nonatomic, assign) NSInteger loopCount; // loopCount <= 0 表示无限循环播放，默认是 1

@property (nonatomic, weak) id<XCFAVPlayerViewDelegate> delegate;

- (NSTimeInterval) duration;
- (NSTimeInterval) currentTime;

- (BOOL) seekToSecond:(NSTimeInterval)second;

@end

NS_ASSUME_NONNULL_END
