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

- (void) avPlayerViewDidReadyToPlay:(XCFAVPlayerView *)playerView;
- (void) avPlayerView:(XCFAVPlayerView *)playerView failedToPlayWithError:(NSError *)error;
- (void) avPlayerViewDidPlayToEnd:(XCFAVPlayerView *)playerView;
- (void) avPlayerViewDidUpgradeProgress:(XCFAVPlayerView *)playerView;

@end

@interface XCFAVPlayerView : UIView<XCFVideoPlayerControlProtocol>

- (void) prepareToPlayVideoAtPath:(NSString *)videoPath;
- (void) prepareToPlayVideoAtAsset:(AVAsset *)asset;
- (void) prepareToPlayVideoWithURL:(NSURL *)videoURL;

@property (nonatomic, assign) BOOL fillPlayerWindow; // default is YES

@property (nonatomic, assign) NSInteger loopCount; // loopCount <= 0 表示无限循环播放，默认是 1

@property (nonatomic, weak) id<XCFAVPlayerViewDelegate> delegate;

@property (nonatomic, assign) float volume; // 音量

- (NSTimeInterval) duration;
- (NSTimeInterval) currentTime;

- (nullable UIImage *) snapshotOfCurrentFrame;

- (BOOL) seekToSecond:(NSTimeInterval)second;
- (void) asyncSeekToSecond:(NSTimeInterval)second completion:(void (^)(BOOL finish))completion;

- (CGRect) videoRect;

@end

NS_ASSUME_NONNULL_END
