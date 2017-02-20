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

@class XCFAVPlayerView,AVAsset;

@protocol XCFAVPlayerViewDelegate <NSObject>

@optional

- (void) avPlayerViewDidPlayToEnd:(XCFAVPlayerView *)playerView;
- (void) avPlayerViewDidUpgradeProgress:(XCFAVPlayerView *)playerView;

@end

@interface XCFAVPlayerView : UIView<XCFVideoPlayerControlProtocol>

- (void) prepareToPlayVideoAtPath:(NSString *)videoPath
                       completion:(nullable void (^)(BOOL completion,NSError *_Nullable error))completion;
- (void) prepareToPlayVideoAtAsset:(AVAsset *)asset completion:(nullable void (^)(BOOL completion, NSError * _Nullable error))completion;

- (void) prepareToPlayVideoWithURL:(NSURL *)videoURL;

@property (nonatomic, assign) NSInteger loopCount; // loopCount <= 0 表示无限循环播放，默认是 1

@property (nonatomic, weak) id<XCFAVPlayerViewDelegate> delegate;

@property (nonatomic, assign) float volume; // 音量

- (NSTimeInterval) duration;
- (NSTimeInterval) currentTime;

- (BOOL) seekToSecond:(NSTimeInterval)second;
- (void) asyncSeekToSecond:(NSTimeInterval)second completion:(void (^)(BOOL finish))completion;

- (CGRect) videoRect;

@end

NS_ASSUME_NONNULL_END
