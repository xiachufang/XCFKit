//
//  XCFVideoEditorController.m
//  XCFKit
//
//  Created by Li Guoyin on 2017/1/4.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import "XCFVideoEditorController.h"
#import <AVFoundation/AVFoundation.h>

#import "XCFVideoRangeSlider.h"
#import "XCFAVPlayerView.h"

@interface XCFVideoEditorController ()<XCFAVPlayerViewDelegate>

@property (nonatomic, strong) AVAsset *videoAsset;
@property (nonatomic, strong) AVAssetExportSession *exportSession;

@property (nonatomic, strong) XCFAVPlayerView *playerView;
@property (nonatomic, strong) UIScrollView *playerScrollView;

@property (nonatomic, strong) XCFVideoRangeSlider *videoRangeSlider;
@property (nonatomic, assign) XCFVideoRange currentRange;

@end

@implementation XCFVideoEditorController
{
    BOOL _pause;
}

+ (BOOL) canEditVideoAtPath:(NSString *)videoPath
{
    return [UIVideoEditorController canEditVideoAtPath:videoPath];
}

+ (void) loadVideoAssetAtPath:(NSString *)videoPath
                   completion:(void (^)(AVAsset *asset,NSError *error))completion
{
    if (completion) {
        NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey : @(YES)};
        AVAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:videoPath]
                                             options:options];
        NSArray<NSString *> *loadKeys = @[@"tracks",@"playable"];
        [asset loadValuesAsynchronouslyForKeys:loadKeys completionHandler:^{
            NSError *error = nil;
            for (NSString *key in loadKeys) {
                AVKeyValueStatus __unused status = [asset statusOfValueForKey:key error:&error];
                if (error) break;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(asset,error);
                }
            });
        }];
    }
}

- (instancetype) initWithVideoPath:(NSString *)videoPath
{
    NSParameterAssert(videoPath);
    
    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey : @(YES)};
    AVAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:videoPath]
                                         options:options];
    return [self initWithVideoAsset:asset];
}

- (instancetype) initWithVideoAsset:(AVAsset *)asset
{
    self = [super initWithNibName:nil bundle:nil];
    if (self ) {
        _videoQuality = XCFVideoEditorVideoQualityTypeMedium | XCFVideoEditorVideoQualityType1x1;
        _videoMinimumDuration = 3.0f;
        _videoMaximumDuration = 10.0f;
        
        _videoAsset = asset;
        
        self.title = @"Trim & Crop";
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    return self;
}

- (void) loadView
{
    [super loadView];
    
    // bg
    self.view.backgroundColor = [UIColor blackColor];
    
    // player
    _playerScrollView = [[UIScrollView alloc] initWithFrame:[self _playerContainerFrame]];
    _playerScrollView.scrollsToTop = NO;
    _playerScrollView.showsVerticalScrollIndicator = NO;
    _playerScrollView.showsHorizontalScrollIndicator = NO;
    _playerScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    _playerScrollView.clipsToBounds = YES;
    [self.view addSubview:_playerScrollView];
    
    // load assets
    NSString *loadkey = @"tracks";
    
    __weak typeof(self) weak_self = self;
    [self.videoAsset loadValuesAsynchronouslyForKeys:@[loadkey] completionHandler:^{
        __strong typeof(weak_self) strong_self = weak_self;
        NSError *error = nil;
        AVKeyValueStatus status = [strong_self.videoAsset statusOfValueForKey:loadkey
                                                                        error:&error];
        if (status == AVKeyValueStatusLoaded) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [strong_self didVideoAssetLoaded];
            });
        }
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - layout

- (CGFloat) _playerContainerHeightWidthRatio
{
    if (self.videoQuality & XCFVideoEditorVideoQualityType4x3) {
        return 3.0 / 4.0;
    }
    
    return 1;
}

- (CGRect) _playerContainerFrame
{
    CGFloat width = self.view.bounds.size.width;
    CGFloat ratio = [self _playerContainerHeightWidthRatio];
    CGFloat height = width * ratio;
    
    CGFloat toplayoutHeight = [self.topLayoutGuide length];
    return CGRectMake(0, toplayoutHeight, width, height);
}

- (CGRect) _videoRangeSliderFrame
{
    CGFloat sliderHeight = 78;
    CGFloat topSpaceBetweenPlayer = 12;
    
    CGRect frame = [self _playerContainerFrame];
    frame.origin.y += frame.size.height + topSpaceBetweenPlayer;
    frame.size.height = sliderHeight;
    
    return frame;
}

- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.playerScrollView.frame = [self _playerContainerFrame];
    self.videoRangeSlider.frame = [self _videoRangeSliderFrame];
}

#pragma mark - video 

- (void) didVideoAssetLoaded
{
    AVAssetTrack *track = [self.videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    CGSize videoSize = track.naturalSize;
    CGAffineTransform transform = track.preferredTransform;
    if (transform.d == 0) {
        videoSize = CGSizeMake(videoSize.height, videoSize.width);
    }
    
    CGSize playerContainerSize = [self _playerContainerFrame].size;
    CGSize videoPlayerContentSize;
    CGFloat ratio = videoSize.height / videoSize.width;
    
    if (ratio >= [self _playerContainerHeightWidthRatio]) {
        videoPlayerContentSize.width = playerContainerSize.width;
        videoPlayerContentSize.height = playerContainerSize.width * ratio;
    } else if (ratio > 0) {
        videoPlayerContentSize.height = playerContainerSize.height;
        videoPlayerContentSize.width = playerContainerSize.height / ratio;
    } else {
        videoPlayerContentSize = videoSize;
    }
    
    _playerView = [[XCFAVPlayerView alloc] initWithFrame:(CGRect){CGPointZero,videoPlayerContentSize}];
    [self.playerScrollView addSubview:_playerView];
    self.playerScrollView.contentSize = videoPlayerContentSize;
    self.playerScrollView.contentOffset =
    CGPointMake((videoPlayerContentSize.width - playerContainerSize.width)/2,
                (videoPlayerContentSize.height - playerContainerSize.height)/2);
    
    _playerView.delegate = self;
    _playerView.loopCount = 0;
    
    __weak typeof(self) weak_self = self;
    [_playerView prepareToPlayVideoAtAsset:self.videoAsset completion:^(BOOL finish, NSError * _Nullable error) {
        if (finish) {
            __strong typeof(weak_self) strong_self = weak_self;
            [strong_self.playerView play];
        }
    }];
    
    _videoRangeSlider = [[XCFVideoRangeSlider alloc] initWithFrame:[self _videoRangeSliderFrame]];
    _videoRangeSlider.minimumTrimLength = self.videoMinimumDuration;
    _videoRangeSlider.maximumTrimLength = self.videoMaximumDuration;
    _videoRangeSlider.tintColor = [UIColor orangeColor];
    [self.view addSubview:_videoRangeSlider];
    
    [_videoRangeSlider addTarget:self
                          action:@selector(videoRangeDidChanged:)
                forControlEvents:UIControlEventValueChanged];
    [_videoRangeSlider loadVideoFramesWithVideoAsset:self.videoAsset];
}

#pragma mark - action

- (void) videoRangeDidChanged:(XCFVideoRangeSlider *)slider
{
    if (slider.isTracking) {
        [self.playerView pause];
    }
    
    XCFVideoRange range = slider.currentRange;
    NSTimeInterval targetSecond = -1;
    if (XCFVideoRangeGetEnd(range) != XCFVideoRangeGetEnd(self.currentRange)) {
        targetSecond = XCFVideoRangeGetEnd(range);
    } else if (range.location != self.currentRange.location) {
        targetSecond = range.location;
    } else if (!slider.isTracking && !_pause) {
        [self.playerView play];
    }
    
    if (targetSecond > 0) {
        __weak typeof(self) weak_self = self;
        [self.playerView asyncSeekToSecond:targetSecond completion:^(BOOL finish) {
            __strong typeof(weak_self) strong_self = weak_self;
            if (finish && strong_self && !strong_self.videoRangeSlider.isTracking && !strong_self->_pause) {
                [strong_self.playerView play];
            }
        }];
    }
    
    self.currentRange = range;
}

#pragma mark - XCFAVPlayerViewDelegate

- (void) avPlayerViewDidPlayToEnd:(XCFAVPlayerView *)playerView
{
    if ([playerView seekToSecond:self.currentRange.location]) {
        [playerView play];
    }
}

- (void) avPlayerViewDidUpgradeProgress:(XCFAVPlayerView *)playerView
{
    NSTimeInterval end = XCFVideoRangeGetEnd(self.currentRange);
    if (playerView.progress < 1 && playerView.isPlaying && end > 0 && playerView.duration * playerView.progress >= end) {
        [self avPlayerViewDidPlayToEnd:playerView];
    }
}

@end
