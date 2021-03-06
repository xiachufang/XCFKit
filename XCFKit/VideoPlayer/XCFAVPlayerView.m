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

@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayerItemVideoOutput *playerItemOutput;
@property (nonatomic, strong) AVAsset *videoAsset;

@end

@implementation XCFAVPlayerView {
    struct {
        unsigned int readyPlay : 1;
        unsigned int failed : 1;
        unsigned int playToEnd : 1;
        unsigned int progress : 1;
        unsigned int pause : 1;
    } _delegateFlag;

    NSInteger _actualLoopCount;

    id _playerTimeObserver;
    __weak AVPlayerItem *_didDisplayItem;
}

#pragma mark - life cycle

- (void)dealloc {
    [self cleanup];
    [self removeObservePlayerLayerReadyToDisplay];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:nil];
}

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _loopCount = 1;
        _volume = 1;
        _fillPlayerWindow = YES;
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.backgroundColor = [UIColor blackColor];

        [self observePlayerLayerReadyToDisplay];
    }

    return self;
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)self.layer;
}

#pragma mark - layout

- (CGRect)videoRect {
    return self.playerLayer.videoRect;
}

#pragma mark - delegate

- (void)setDelegate:(id<XCFAVPlayerViewDelegate>)delegate {
    _delegate = delegate;

    _delegateFlag.readyPlay = [delegate respondsToSelector:@selector(avPlayerViewDidReadyToPlay:)];
    _delegateFlag.failed = [delegate respondsToSelector:@selector(avPlayerView:failedToPlayWithError:)];
    _delegateFlag.playToEnd = [delegate respondsToSelector:@selector(avPlayerViewDidPlayToEnd:)];
    _delegateFlag.progress = [delegate respondsToSelector:@selector(avPlayerViewDidUpgradeProgress:)];
    _delegateFlag.pause = [delegate respondsToSelector:@selector(avPlayerViewDidPause:)];
}

#pragma mark - logic

- (void)upgradeProgress {
    if (_delegateFlag.progress && self.isPlaying) {
        [self.delegate avPlayerViewDidUpgradeProgress:self];
    }
}

- (void)readyToPlay {
    if (_delegateFlag.readyPlay) {
        [self.delegate avPlayerViewDidReadyToPlay:self];
    }
}

- (void)preparedFailed:(NSError *)error {
    if (_delegateFlag.failed) {
        [self.delegate avPlayerView:self failedToPlayWithError:error];
    }
}

#pragma mark - util

- (UIImage *)snapshotOfCurrentFrame {
    if (self.playerItemOutput) {
        CVPixelBufferRef buffer = [self.playerItemOutput copyPixelBufferForItemTime:[self.playerItem currentTime]
                                                                 itemTimeForDisplay:nil];
        if (buffer) {
            CIImage *ciImage = [CIImage imageWithCVPixelBuffer:buffer];
            CIContext *context = [CIContext contextWithOptions:NULL];
            CGRect rect = CGRectMake(0,
                                     0,
                                     CVPixelBufferGetWidth(buffer),
                                     CVPixelBufferGetHeight(buffer));
            CGImageRef cgImage = [context createCGImage:ciImage fromRect:rect];
            CVBufferRelease(buffer);
            UIImage *image = [UIImage imageWithCGImage:cgImage];
            CGImageRelease(cgImage);
            return image;
        }
    }

    return nil;
}

#pragma mark - volume

- (void)setVolume:(float)volume {
    _volume = volume;
    self.playerLayer.player.volume = volume;
}

#pragma mark - fill mode

- (void)setFillPlayerWindow:(BOOL)fillPlayerWindow {
    if (_fillPlayerWindow != fillPlayerWindow) {
        _fillPlayerWindow = fillPlayerWindow;

        self.playerLayer.videoGravity = _fillPlayerWindow ? AVLayerVideoGravityResizeAspectFill : AVLayerVideoGravityResizeAspect;
    }
}

#pragma mark - play

- (void)cleanup {
    if (_playerTimeObserver) {
        [self.playerLayer.player removeTimeObserver:_playerTimeObserver];
        _playerTimeObserver = nil;
    }

    [self.playerItem cancelPendingSeeks];
    [self.playerLayer.player replaceCurrentItemWithPlayerItem:nil];
    [self removeObserverOnPlayerItem];
    self.playerItem = nil;
}

- (void)prepareToPlayVideoAtPath:(NSString *)videoPath {
    NSParameterAssert(videoPath);

    NSURL *url = [NSURL fileURLWithPath:videoPath];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    [self prepareToPlayVideoAtAsset:asset];
}

- (void)prepareToPlayVideoAtAsset:(AVAsset *)asset {
    [self stop];

    self.videoAsset = asset;

    NSArray *loadKeys = @[@"playable"];
    __weak AVAsset *weak_asset = asset;
    __weak typeof(self) weak_self = self;
    [asset loadValuesAsynchronouslyForKeys:loadKeys
                         completionHandler:^{
                             __strong AVAsset *strong_asset = weak_asset;
                             NSString *loadKey = loadKeys.firstObject;
                             NSError *error = nil;
                             AVKeyValueStatus status = [strong_asset statusOfValueForKey:loadKey error:&error];

                             if (status == AVKeyValueStatusLoaded && strong_asset.isPlayable) {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     __strong typeof(weak_self) strong_self = weak_self;
                                     if (!strong_self)
                                         return;

                                     if (strong_self.playerItem) {
                                         [strong_self removeObserverOnPlayerItem];
                                     }
                                     strong_self.playerItem = [AVPlayerItem playerItemWithAsset:strong_asset
                                                                   automaticallyLoadedAssetKeys:@[@"duration"]];
                                     NSDictionary *settings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
                                     strong_self.playerItemOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:settings];
                                     [strong_self.playerItem addOutput:strong_self.playerItemOutput];
                                     if ([self.delegate respondsToSelector:@selector(avPlayerViewPreferredForwardBufferDuration)]) {
                                         if (@available(iOS 10.0, *)) {
                                             strong_self.playerItem.preferredForwardBufferDuration = [self.delegate avPlayerViewPreferredForwardBufferDuration];
                                         } 
                                     }
                                     
                                     [[NSNotificationCenter defaultCenter] addObserver:strong_self
                                                                              selector:@selector(didPlayToEndNotification:)
                                                                                  name:AVPlayerItemDidPlayToEndTimeNotification
                                                                                object:strong_self.playerItem];

                                     AVPlayer *player = strong_self.playerLayer.player;
                                     if (!player) {
                                         player = [AVPlayer playerWithPlayerItem:strong_self.playerItem];
                                         strong_self.playerLayer.player = player;
                                     } else {
                                         [player replaceCurrentItemWithPlayerItem:strong_self.playerItem];
                                     }

                                     player.volume = strong_self.volume;

                                     [strong_self observePlayerItemStatus];
                                 });
                             } else {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     __strong typeof(weak_self) strong_self = weak_self;
                                     if (!strong_self)
                                         return;

                                     [strong_self preparedFailed:error];
                                 });
                             }
                         }];
}

- (void)prepareToPlayVideoWithURL:(NSURL *)videoURL {
    if (!videoURL) {
        [self cleanup];
    } else if ([videoURL isFileURL]) {
        [self prepareToPlayVideoAtPath:videoURL.path];
    } else {
        AVURLAsset *asset = [AVURLAsset assetWithURL:videoURL];
        [self prepareToPlayVideoAtAsset:asset];
    }
}

#pragma mark - observe status

static void const *_observeStatusContext = (void *)&_observeStatusContext;

- (void)observePlayerItemStatus {
    [self.playerItem addObserver:self
                      forKeyPath:NSStringFromSelector(@selector(status))
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:&_observeStatusContext];
}

- (void)removeObserverOnPlayerItem {
    [self.playerItem removeObserver:self
                         forKeyPath:NSStringFromSelector(@selector(status))
                            context:&_observeStatusContext];
}

- (void)observePlayerLayerReadyToDisplay {
    [self.playerLayer addObserver:self
                       forKeyPath:@"readyForDisplay"
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:&_observeStatusContext];
}

- (void)removeObservePlayerLayerReadyToDisplay {
    [self.playerLayer removeObserver:self
                          forKeyPath:@"readyForDisplay"
                             context:&_observeStatusContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    // 通过 context 可以判定 keypath 一定是 status 所以不再在这里判断
    if (object == self.playerItem && context == _observeStatusContext) {
        AVPlayerItemStatus status = self.playerItem.status;

        if (status == AVPlayerItemStatusFailed) {
            [self preparedFailed:self.playerItem.error];
        }
    } else if (object == self.playerLayer && context == _observeStatusContext) {
        AVPlayerItem *item = [(AVPlayerLayer *)object player].currentItem;
        if (item != _didDisplayItem && self.playerLayer.isReadyForDisplay) {
            [self readyToPlay];
            _didDisplayItem = item;
        }
    }
}

#pragma mark - notification

- (void)didPlayToEndNotification:(NSNotification *)notification {
    if (notification.object == self.playerItem) {
        _actualLoopCount++;

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

- (CGFloat)timeBaseRate {
    CGFloat rate = 0;

    AVPlayer *player = self.playerLayer.player;
    CMTimebaseRef rateRef = player.currentItem.timebase;

    if (rateRef) {
        rate = (CGFloat)CMTimebaseGetRate(rateRef);
    }

    return rate;
}

- (CGFloat)rate {
    return self.playerLayer.player.rate;
}

- (NSTimeInterval)currentTime {
    return CMTimeGetSeconds(self.playerLayer.player.currentTime);
}

- (NSTimeInterval)duration {
    if (self.playerItem && self.playerItem.status != AVPlayerItemStatusFailed) {
        return CMTimeGetSeconds(self.playerItem.duration);
    } else {
        return -1;
    }
}

- (BOOL)seekToSecond:(NSTimeInterval)second {
    if (self.isPlayable && second >= 0 && second <= [self duration]) {
        [self.playerLayer.player seekToTime:CMTimeMakeWithSeconds(second, NSEC_PER_SEC)];
        return YES;
    }

    return NO;
}

- (void)asyncSeekToSecond:(NSTimeInterval)second completion:(void (^)(BOOL))completion {
    if (self.isPlayable && second >= 0 && second <= [self duration]) {
        [self.playerLayer.player seekToTime:CMTimeMakeWithSeconds(second, NSEC_PER_SEC)
                          //                            toleranceBefore:kCMTimeZero
                          //                             toleranceAfter:kCMTimeZero
                          completionHandler:completion];
    } else {
        if (completion) {
            completion(NO);
        }
    }
}

#pragma mark - XCFVideoPlayerControlProtocol

- (BOOL)isPlayable {
    return self.playerLayer.player.status == AVPlayerStatusReadyToPlay;
}

- (void)play {
    if (self.isPlayable) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                                   error:nil];
        });
        [self.playerLayer.player play];

        if (!_playerTimeObserver) {
            __weak typeof(self) weak_self = self;

            CMTime interval = CMTimeMake(1, 30);
            _playerTimeObserver =
                [self.playerLayer.player addPeriodicTimeObserverForInterval:interval
                                                                      queue:dispatch_get_main_queue()
                                                                 usingBlock:^(CMTime time) {
                                                                     [weak_self upgradeProgress];
                                                                 }];
        }
    }
}

- (void)pause {
    if (self.isPlayable) {
        [self.playerLayer.player pause];
        if (_delegateFlag.pause) {
            [self.delegate avPlayerViewDidPause:self];
        }
    }
}

- (void)stop {
    if (self.isPlayable) {
        [self.playerLayer.player seekToTime:kCMTimeZero];
        [self.playerLayer.player pause];
    }

    _actualLoopCount = 0;
}

- (BOOL)isPlaying {
    return [self timeBaseRate] != 0;
}

- (CGFloat)progress {
    NSTimeInterval duration = [self duration];
    if (duration > 0) {
        return [self currentTime] / duration;
    } else {
        return -1;
    }
}

@end
