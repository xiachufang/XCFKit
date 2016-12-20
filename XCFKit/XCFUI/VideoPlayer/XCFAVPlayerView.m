//
//  XCFAVPlayerView.m
//  XCFKit
//
//  Created by Li Guoyin on 2016/12/19.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import "XCFAVPlayerView.h"
#import <AVFoundation/AVFoundation.h>

@interface XCFAVPlayerView ()

@property (nonatomic, copy) NSString *videoPath;

@property (nonatomic, retain) AVPlayerItem *playerItem;
@property (nonatomic, retain) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) AVURLAsset *videoAsset;

@end

@implementation XCFAVPlayerView
{
    struct {
        unsigned int playToEnd : 1;
        unsigned int progress  : 1;
    } _delegateFlag;
    
    NSInteger _actualLoopCount;
    
    id _playerTimeObserver;
}

#pragma mark - life cycle

- (void) dealloc
{
    [self cleanup];
}

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _loopCount = 1;
        
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:nil];
        [self.layer addSublayer:_playerLayer];
    }
    
    return self;
}

#pragma mark - layout

- (void) layoutSubviews
{
    [super layoutSubviews];
    _playerLayer.frame = self.layer.bounds;
}

- (CGRect) videoRect
{
    return self.playerLayer.videoRect;
}

#pragma mark - delegate

- (void) setDelegate:(id<XCFAVPlayerViewDelegate>)delegate
{
    _delegate = delegate;
    _delegateFlag.playToEnd = [delegate respondsToSelector:@selector(avPlayerViewDidPlayToEnd:)];
    _delegateFlag.progress = [delegate respondsToSelector:@selector(avPlayerViewDidUpgradeProgress:)];
}

- (void) upgradeProgress
{
    if (_delegateFlag.progress && self.isPlaying) {
        [self.delegate avPlayerViewDidUpgradeProgress:self];
    }
}

#pragma mark - play

- (void) cleanup
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:self.playerItem];
    
    if (_playerTimeObserver) {
        [self.playerLayer.player removeTimeObserver:_playerTimeObserver];
        _playerTimeObserver = nil;
    }
    
    [self.playerItem cancelPendingSeeks];
    [self.playerLayer.player replaceCurrentItemWithPlayerItem:nil];
    self.playerItem = nil;
    self.playerLayer.player = nil;
}

- (void) prepareToPlayVideoAtPath:(NSString *)videoPath completion:(void (^)(BOOL, NSError * _Nullable))completion
{
    NSParameterAssert(videoPath);
    
    [self stop];
    
    self.videoPath = videoPath;
    
    NSURL *url = [NSURL fileURLWithPath:videoPath];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    self.videoAsset = asset;
    NSArray *loadKeys = @[@"playable"];
    __weak AVURLAsset *weak_asset = asset;
    __weak typeof(self) weak_self = self;
    [asset loadValuesAsynchronouslyForKeys:loadKeys completionHandler:^{
        __strong AVURLAsset *strong_asset = weak_asset;
        NSString *loadKey = loadKeys.firstObject;
        NSError *error = nil;
        AVKeyValueStatus status = [strong_asset statusOfValueForKey:loadKey error:&error];
        
        if (status == AVKeyValueStatusLoaded && strong_asset.isPlayable) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weak_self) strong_self = weak_self;
                if (!strong_self) return;
                
                strong_self.playerItem = [AVPlayerItem playerItemWithAsset:strong_asset];
                [[NSNotificationCenter defaultCenter] addObserver:strong_self
                                                         selector:@selector(didPlayToEndNotification:)
                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                           object:strong_self.playerItem];
                
                if (!strong_self.playerLayer.player) {
                    AVPlayer *player = [AVPlayer playerWithPlayerItem:strong_self.playerItem];
                    strong_self.playerLayer.player = player;
                } else {
                    [strong_self.playerLayer.player replaceCurrentItemWithPlayerItem:strong_self.playerItem];
                }
                
                if (completion) {
                    completion(YES,nil);
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weak_self) strong_self = weak_self;
                if (!strong_self) return;
                
                if (completion) {
                    completion(NO,error);
                }
            });
        }
    }];
}

#pragma mark - notification

- (void) didPlayToEndNotification:(NSNotification *)notification
{
    if (notification.object == self.playerItem) {
        _actualLoopCount ++;
        
        if (self.loopCount <= 0 || _actualLoopCount < self.loopCount) {
            [self.playerLayer.player seekToTime:kCMTimeZero];
            [self.playerLayer.player play];
        }
        
        if (_delegateFlag.playToEnd) {
            [self.delegate avPlayerViewDidPlayToEnd:self];
        }
    }
}

#pragma mark - time

- (NSTimeInterval) currentTime
{
    return CMTimeGetSeconds(self.playerLayer.player.currentTime);
}

- (NSTimeInterval) duration
{
    if (self.playerItem && self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
        return CMTimeGetSeconds(self.playerItem.duration);
    } else {
        return -1;
    }
}

- (BOOL) seekToSecond:(NSTimeInterval)second
{
    if (self.isPlayable && second >= 0 && second < [self duration]) {
        [self.playerLayer.player pause];
        [self.playerLayer.player seekToTime:CMTimeMakeWithSeconds(second, NSEC_PER_SEC)];
        return YES;
    }
    
    return NO;
}

#pragma mark - XCFVideoPlayerControlProtocol

- (BOOL) isPlayable
{
    return self.playerLayer.player.status == AVPlayerStatusReadyToPlay;
}

- (void) play
{
    if (self.isPlayable) {
        [self.playerLayer.player play];
        
        if (!_playerTimeObserver) {
            __weak typeof(self) weak_self = self;
            
            CMTime interval = CMTimeMakeWithSeconds(12.0 / 60.0, NSEC_PER_SEC);
            _playerTimeObserver =
            [self.playerLayer.player addPeriodicTimeObserverForInterval:interval
                                                                  queue:dispatch_get_main_queue()
                                                             usingBlock:^(CMTime time) {
                                                                 [weak_self upgradeProgress];
                                                             }];
        }
    }
}

- (void) pause
{
    if (self.isPlayable) {
        [self.playerLayer.player pause];
    }
}

- (void) stop
{
    if (self.isPlayable) {
        [self.playerLayer.player seekToTime:kCMTimeZero];
        [self.playerLayer.player pause];
    }

    _actualLoopCount = 0;
}

- (BOOL) isPlaying
{
    return self.playerLayer.player.timeControlStatus == AVPlayerTimeControlStatusPlaying;
}

- (CGFloat) progress
{
    NSTimeInterval duration = [self duration];
    if (duration > 0) {
        return [self currentTime] / [self duration];
    } else {
        return -1;
    }
}

@end
