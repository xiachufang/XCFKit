//
//  XCFAVPlayerView.h
//  XCFKit
//
//  Created by Li Guoyin on 2016/12/19.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import "XCFVideoPlayerControlProtocol.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class XCFAVPlayerView, AVAsset, AVPlayerLayer;

@protocol XCFAVPlayerViewDelegate <NSObject>

@optional

- (void)avPlayerViewDidReadyToPlay:(XCFAVPlayerView *)playerView;
- (void)avPlayerView:(XCFAVPlayerView *)playerView failedToPlayWithError:(NSError *)error;
- (void)avPlayerViewDidPlayToEnd:(XCFAVPlayerView *)playerView;
- (void)avPlayerViewDidUpgradeProgress:(XCFAVPlayerView *)playerView;
- (void)avPlayerViewDidPause:(XCFAVPlayerView *)playerView;
// playitem.preferredForwardBufferDuration iOS10 以后有效
- (NSTimeInterval)avPlayerViewPreferredForwardBufferDuration;
@end

@interface XCFAVPlayerView : UIView <XCFVideoPlayerControlProtocol>

- (void)prepareToPlayVideoAtPath:(NSString *)videoPath;
- (void)prepareToPlayVideoAtAsset:(AVAsset *)asset;
- (void)prepareToPlayVideoWithURL:(nullable NSURL *)videoURL;

@property (nonatomic, assign) BOOL fillPlayerWindow; // default is YES

@property (nonatomic, assign) NSInteger loopCount; // loopCount <= 0 表示无限循环播放，默认是 1

@property (nonatomic, weak) id<XCFAVPlayerViewDelegate> delegate;

@property (nonatomic, assign) float volume; // 音量

- (AVPlayerLayer *)playerLayer;

- (NSTimeInterval)duration;
- (NSTimeInterval)currentTime;

- (CGFloat)rate;
- (CGFloat)timeBaseRate;

- (nullable UIImage *)snapshotOfCurrentFrame;

- (BOOL)seekToSecond:(NSTimeInterval)second;
- (void)asyncSeekToSecond:(NSTimeInterval)second completion:(void (^)(BOOL finish))completion;

- (CGRect)videoRect;

@end

NS_ASSUME_NONNULL_END
