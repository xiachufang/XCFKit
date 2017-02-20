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
        unsigned int readyPlay : 1;
        unsigned int failed    : 1;
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
        _volume = 1;
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:nil];
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
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
    
    _delegateFlag.readyPlay = [delegate respondsToSelector:@selector(avPlayerViewDidReadyToPlay:)];
    _delegateFlag.failed    = [delegate respondsToSelector:@selector(avPlayerView:failedToPlayWithError:)];
    _delegateFlag.playToEnd = [delegate respondsToSelector:@selector(avPlayerViewDidPlayToEnd:)];
    _delegateFlag.progress = [delegate respondsToSelector:@selector(avPlayerViewDidUpgradeProgress:)];
}

#pragma mark - logic

- (void) upgradeProgress
{
    if (_delegateFlag.progress && self.isPlaying) {
        [self.delegate avPlayerViewDidUpgradeProgress:self];
    }
}

- (void) readyToPlay
{
    if (_delegateFlag.readyPlay) {
        [self.delegate avPlayerViewDidReadyToPlay:self];
    }
}

- (void) preparedFailed:(NSError *)error
{
    if (_delegateFlag.failed) {
        [self.delegate avPlayerView:self failedToPlayWithError:error];
    }
}

#pragma mark - volume

- (void) setVolume:(float)volume
{
    _volume = volume;
    self.playerLayer.player.volume = volume;
}

#pragma mark - play

- (void) cleanup
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:nil];
    
    if (_playerTimeObserver) {
        [self.playerLayer.player removeTimeObserver:_playerTimeObserver];
        _playerTimeObserver = nil;
    }
    
    [self.playerItem cancelPendingSeeks];
    [self.playerLayer.player replaceCurrentItemWithPlayerItem:nil];
    [self removeObserverOnPlayerItem];
    self.playerItem = nil;
    self.playerLayer.player = nil;
}

- (void) prepareToPlayVideoAtPath:(NSString *)videoPath
{
    NSParameterAssert(videoPath);
    
    NSURL *url = [NSURL fileURLWithPath:videoPath];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    [self prepareToPlayVideoAtAsset:asset];
}

- (void) prepareToPlayVideoAtAsset:(AVAsset *)asset
{
    [self stop];
    
    self.videoAsset = (AVURLAsset*)asset;
    self.videoPath = self.videoAsset.URL.path;
    
    NSArray *loadKeys = @[@"playable"];
    __weak AVAsset *weak_asset = asset;
    __weak typeof(self) weak_self = self;
    [asset loadValuesAsynchronouslyForKeys:loadKeys completionHandler:^{
        __strong AVAsset *strong_asset = weak_asset;
        NSString *loadKey = loadKeys.firstObject;
        NSError *error = nil;
        AVKeyValueStatus status = [strong_asset statusOfValueForKey:loadKey error:&error];
        
        if (status == AVKeyValueStatusLoaded && strong_asset.isPlayable) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weak_self) strong_self = weak_self;
                if (!strong_self) return;
                
                strong_self.playerItem = [AVPlayerItem playerItemWithAsset:strong_asset
                                              automaticallyLoadedAssetKeys:@[@"duration"]];
                [[NSNotificationCenter defaultCenter] addObserver:strong_self
                                                         selector:@selector(didPlayToEndNotification:)
                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                           object:strong_self.playerItem];
                
                if (!strong_self.playerLayer.player) {
                    AVPlayer *player = [AVPlayer playerWithPlayerItem:strong_self.playerItem];
                    player.volume = strong_self.volume;
                    strong_self.playerLayer.player = player;
                } else {
                    [strong_self.playerLayer.player replaceCurrentItemWithPlayerItem:strong_self.playerItem];
                }
                
                [strong_self observePlayerItemStatus];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weak_self) strong_self = weak_self;
                if (!strong_self) return;
                
                [strong_self preparedFailed:error];
            });
        }
    }];
}

- (void) prepareToPlayVideoWithURL:(NSURL *)videoURL
{
    NSParameterAssert(videoURL);
    
    if (!videoURL) return;
    
    if ([videoURL isFileURL]) {
        [self prepareToPlayVideoAtPath:videoURL.path];
    } else {
        self.videoPath = videoURL.absoluteString;
        self.videoAsset = nil;
        
        self.playerItem = [[AVPlayerItem alloc] initWithURL:videoURL];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didPlayToEndNotification:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:self.playerItem];
        
        if (self.playerLayer.player) {
            [self.playerLayer.player replaceCurrentItemWithPlayerItem:self.playerItem];
        } else {
            AVPlayer *player = [AVPlayer playerWithPlayerItem:self.playerItem];
            player.volume = self.volume;
            self.playerLayer.player = player;
        }
        
        [self observePlayerItemStatus];
    }
}

#pragma mark - observe status

static void const *_observeStatusContext;

- (void) observePlayerItemStatus
{
    [self.playerItem addObserver:self
                       forKeyPath:NSStringFromSelector(@selector(status))
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:&_observeStatusContext];
}

- (void) removeObserverOnPlayerItem
{
    [self.playerItem removeObserver:self
                         forKeyPath:NSStringFromSelector(@selector(status))
                            context:&_observeStatusContext];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    // 通过 context 可以判定 keypath 一定是 status 所以不再在这里判断
    if (object == self.playerItem && context == _observeStatusContext) {
        AVPlayerItemStatus status = self.playerItem.status;
        
        if (status == AVPlayerItemStatusReadyToPlay) {
            [self readyToPlay];
        } else if (status == AVPlayerItemStatusFailed) {
            [self preparedFailed:self.playerItem.error];
        }
    }
}

#pragma mark - notification

- (void) didPlayToEndNotification:(NSNotification *)notification
{
    if (notification.object == self.playerItem) {
        _actualLoopCount ++;
        
        if (self.loopCount <= 0 || _actualLoopCount < self.loopCount) {
            [self.playerLayer.player seekToTime:CMTimeMakeWithSeconds(0, NSEC_PER_SEC)];
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
        [self.playerLayer.player seekToTime:CMTimeMakeWithSeconds(second, NSEC_PER_SEC)];
        return YES;
    }
    
    return NO;
}

- (void) asyncSeekToSecond:(NSTimeInterval)second completion:(void (^)(BOOL))completion
{
    if (self.isPlayable && second >= 0 && second < [self duration]) {
        [self.playerLayer.player seekToTime:CMTimeMakeWithSeconds(second, NSEC_PER_SEC)
                            toleranceBefore:kCMTimeZero
                             toleranceAfter:kCMTimeZero
                          completionHandler:completion];
    } else {
        if (completion) {
            completion(NO);
        }
    }
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
            
            CMTime interval = CMTimeMake(1,30);
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
    AVPlayer *player = self.playerLayer.player;
    return player && (!player.error) && player.rate != 0;
}

- (CGFloat) progress
{
    NSTimeInterval duration = [self duration];
    if (duration > 0) {
        return [self currentTime] / duration;
    } else {
        return -1;
    }
}

@end
