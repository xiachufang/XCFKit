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

#import "UIColor+XCFAppearance.h"

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
    
    struct {
        unsigned int didStart: 1;
        unsigned int didCancel : 1;
        unsigned int didSave : 1;
        unsigned int didFail : 1;
    } _delegateFlag;
    
    BOOL _isExperting;
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

- (void) dealloc
{
    [_exportSession cancelExport];
    [self cancelObserveNotifications];
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
        
        self.title = [self _internalTitle];
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
    
    UIBarButtonItem *expertButton = [[UIBarButtonItem alloc] initWithTitle:@"完成"
                                                                     style:UIBarButtonItemStyleDone
                                                                    target:self
                                                                    action:@selector(expertVideo:)];
    self.navigationItem.rightBarButtonItem = expertButton;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"取消"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(cancelEdit:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(_pauseVideo:)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    tapGesture.cancelsTouchesInView = NO;
    [self.playerScrollView addGestureRecognizer:tapGesture];
    
    [self observeNotifications];
}

- (void) setDelegate:(id<XCFVideoEditorControllerDelegate>)delegate
{
    _delegate = delegate;
    
    _delegateFlag.didCancel = [delegate respondsToSelector:@selector(videoEditorDidCancelEdit:)];
    _delegateFlag.didStart = [delegate respondsToSelector:@selector(videoEditorDidStartExport:)];
    _delegateFlag.didSave = [delegate respondsToSelector:@selector(videoEditorController:didSaveEditedVideoToPath:videoInfo:)];
    _delegateFlag.didFail = [delegate respondsToSelector:@selector(videoEditorController:didFailWithError:)];
}

#pragma mark - layout

- (CGFloat) _playerContainerHeightWidthRatio
{
    if (self.videoQuality & XCFVideoEditorVideoQualityType4x3) {
        return 3.0 / 4.0;
    } else if (self.videoQuality & XCFVideoEditorVideoQualityType5x4) {
        return 4.0 / 5.0;
    }
    
    return 1;
}

- (CGRect) _playerContainerFrame
{
    CGFloat width = self.view.bounds.size.width;
    CGFloat ratio = [self _playerContainerHeightWidthRatio];
    CGFloat height = width * ratio;
    
    CGFloat toplayoutHeight = [self.topLayoutGuide length];
    return CGRectMake(0, toplayoutHeight + 20, width, height);
}

- (CGRect) _videoRangeSliderFrame
{
    CGFloat sliderHeight = 78;
    CGFloat topSpaceBetweenPlayer = 40;
    
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

#pragma mark - data

- (NSString *) _internalTitle
{
    return @"剪辑视频";
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
    _videoRangeSlider.tintColor = [UIColor xcf_linkColor];
    _videoRangeSlider.minimumTrimLength = self.videoMinimumDuration;
    _videoRangeSlider.maximumTrimLength = self.videoMaximumDuration;
    [self.view addSubview:_videoRangeSlider];
    
    [_videoRangeSlider addTarget:self
                          action:@selector(videoRangeDidChanged:)
                forControlEvents:UIControlEventValueChanged];
    [_videoRangeSlider loadVideoFramesWithVideoAsset:self.videoAsset];
}

#pragma mark - action

- (void) _pauseVideo:(id)sender
{
    if (self.videoRangeSlider.isTracking) return;
    
    if (_pause) {
        _pause = NO;
        [self.playerView play];
    } else {
        _pause = YES;
        [self.playerView pause];
    }
}

- (void) videoRangeDidChanged:(XCFVideoRangeSlider *)slider
{
    if (slider.isTracking) {
        [self.playerView pause];
    }
    
    XCFVideoRange range = slider.currentRange;
    NSTimeInterval targetSecond = -1;
    if (range.length != self.currentRange.length) {
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

- (NSString *) _videoExpertPresentName
{
    if (self.videoQuality & XCFVideoEditorVideoQualityTypeLow) {
        return AVAssetExportPresetLowQuality;
    } else if (self.videoQuality & XCFVideoEditorVideoQualityTypeMedium) {
        return AVAssetExportPresetMediumQuality;
    } else {
        return AVAssetExportPresetHighestQuality;
    }
}

- (void) cancelEdit:(id)sender
{
    if (_delegateFlag.didCancel) {
        [self.delegate videoEditorDidCancelEdit:self];
    }
}

- (void) expertVideo:(id)sender
{
    if (!_pause) {
        [self _pauseVideo:sender];
    }
    
    AVAssetTrack *sourceVideoTrack = [self.videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    AVAssetTrack *sourceAudioTrack = [self.videoAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    CGSize videoSize = sourceVideoTrack.naturalSize;
    CGAffineTransform transform = sourceVideoTrack.preferredTransform;
    if (transform.d == 0) {
        videoSize = CGSizeMake(videoSize.height, videoSize.width);
    }
    
    int32_t framePerSecond = 30;
    
    AVMutableComposition *composeAsset = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoTrack = [composeAsset addMutableTrackWithMediaType:AVMediaTypeVideo
                                                         preferredTrackID:kCMPersistentTrackID_Invalid];
//    videoTrack.preferredTransform = transform;
    AVMutableCompositionTrack *audioTrack = [composeAsset addMutableTrackWithMediaType:AVMediaTypeAudio
                                                         preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.frameDuration = CMTimeMake(1, framePerSecond);
    
    CGFloat ratio = videoSize.height / videoSize.width;
    CGFloat expertRatio = [self _playerContainerHeightWidthRatio];
    if (ratio >= expertRatio) {
        videoComposition.renderSize = CGSizeMake(videoSize.width, videoSize.width * expertRatio);
    } else {
        videoComposition.renderSize = CGSizeMake(videoSize.height / expertRatio, videoSize.height);
    }
    
    CGPoint contentOffset = self.playerScrollView.contentOffset;
    CGPoint cropVideoOrigin;CGSize continerSize = self.playerScrollView.contentSize;
    contentOffset.x = MAX(MIN(contentOffset.x, continerSize.width), 0);
    contentOffset.y = MAX(MIN(contentOffset.y, continerSize.height), 0);
    cropVideoOrigin.x = (contentOffset.x / continerSize.width) * videoSize.width;
    cropVideoOrigin.y = (contentOffset.y / continerSize.height) * videoSize.height;
//#if DEBUG
//    CGRect cropVideoRect = (CGRect){cropVideoOrigin,videoComposition.renderSize};
//    NSLog(@"natural size : %@ crop rect : %@",NSStringFromCGSize(videoSize),NSStringFromCGRect(cropVideoRect));
//#endif
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    CMTime start = CMTimeMakeWithSeconds(self.currentRange.location, framePerSecond * 100);
    CMTime duration = CMTimeMakeWithSeconds(self.currentRange.length, framePerSecond * 100);
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, duration);
    
    [videoTrack insertTimeRange:CMTimeRangeMake(start, duration)
                        ofTrack:sourceVideoTrack
                         atTime:kCMTimeZero
                          error:nil];
    [audioTrack insertTimeRange:CMTimeRangeMake(start, duration)
                        ofTrack:sourceAudioTrack
                         atTime:kCMTimeZero
                          error:nil];
    
    AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    
    CGAffineTransform t = transform;
    if (t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0) {
//  UIImageOrientationLeft;
        t = CGAffineTransformMakeTranslation(videoSize.width - cropVideoOrigin.x, -cropVideoOrigin.y );
        t = CGAffineTransformRotate(t, M_PI_2 );
    } else if (t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0) {
// UIImageOrientationRight;
        t = CGAffineTransformMakeTranslation(cropVideoOrigin.x,videoSize.height - cropVideoOrigin.y);
        t = CGAffineTransformRotate(t, -M_PI_2);
    } else if (t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0) {
// UIImageOrientationDown;
        t = CGAffineTransformMakeTranslation(videoSize.width -cropVideoOrigin.x,videoSize.height - cropVideoOrigin.y);
        t = CGAffineTransformRotate(t, M_PI);
    } else {
        // up
        t = CGAffineTransformMakeTranslation(-cropVideoOrigin.x,-cropVideoOrigin.y);
        t = CGAffineTransformRotate(t, 0);
    }
    [transformer setTransform:t atTime:kCMTimeZero];
    
    instruction.layerInstructions = @[transformer];
    videoComposition.instructions = @[instruction];
    
    _exportSession = [[AVAssetExportSession alloc] initWithAsset:composeAsset
                                                      presetName:[self _videoExpertPresentName]];
    _exportSession.videoComposition = videoComposition;
    
    NSString *tempDictionary = NSTemporaryDirectory();
    NSString *fileName = [NSString stringWithFormat:@"%@.mp4",[[NSUUID UUID] UUIDString]];
    NSString *filePath = [tempDictionary stringByAppendingPathComponent:fileName];
    NSURL *expertURL = [NSURL fileURLWithPath:filePath];
    
    __weak typeof(self) weak_self = self;
    _exportSession.outputURL = expertURL;
    _exportSession.outputFileType = AVFileTypeMPEG4;
    
    [self enterExportingStatus];
    
    if (_delegateFlag.didStart) {
        [self.delegate videoEditorDidStartExport:self];
    }
    
    [_exportSession exportAsynchronouslyWithCompletionHandler:^{
        __strong typeof(weak_self) strong_self = weak_self;
        AVAssetExportSession *exporter = strong_self.exportSession;
        AVAssetExportSessionStatus status = [exporter status];
        if (status == AVAssetExportSessionStatusExporting) {
            double progress = exporter.progress;
            dispatch_async(dispatch_get_main_queue(), ^{
                [strong_self updateExpertProgress:progress];
            });
        } else if (status == AVAssetExportSessionStatusCompleted) {
            AVAsset *outputAsset = [AVAsset assetWithURL:expertURL];
            AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:outputAsset];
            imageGenerator.appliesPreferredTrackTransform = YES;
            CGImageRef imageRef = [imageGenerator copyCGImageAtTime:kCMTimeZero
                                                        actualTime:nil
                                                             error:nil];
            UIImage *thumbnailImage = nil;
            if (imageRef) {
                thumbnailImage = [UIImage imageWithCGImage:imageRef];
                CGImageRelease(imageRef);
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [strong_self _expertDone:exporter.outputURL thumbnailImage:thumbnailImage videoSize:videoComposition.renderSize];
            });
        } else if (status == AVAssetExportSessionStatusFailed) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [strong_self _expertFailed:exporter.error];
            });
        } else if (status > AVAssetExportSessionStatusExporting) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [strong_self finishExportStatus];
            });
        }
    }];
}

- (void) _expertDone:(NSURL *)tempURL thumbnailImage:(UIImage *)image videoSize:(CGSize)size
{
    [self.exportSession cancelExport];
    [self finishExportStatus];
    
    if (_delegateFlag.didSave) {
        NSMutableDictionary *mutableVideoInfo = [NSMutableDictionary dictionaryWithCapacity:4];
        
        NSDictionary *videoInfo = @{XCFVideoEditorVideoInfoWidth : @(size.width),
                                    XCFVideoEditorVideoInfoHeight : @(size.height),
                                    XCFVideoEditorVideoInfoDuration : @(self.currentRange.length)};
        [mutableVideoInfo addEntriesFromDictionary:videoInfo];
        
        if (image) {
            [mutableVideoInfo setObject:image forKey:XCFVideoEditorVideoInfoThumbnail];
        }
        
        [self.delegate videoEditorController:self
                    didSaveEditedVideoToPath:tempURL.path
                                   videoInfo:mutableVideoInfo.copy];
        
        // delete temp file
//        [[NSFileManager defaultManager] removeItemAtURL:tempURL error:nil];
    }
}

- (void) _expertFailed:(NSError *)error
{
    [self.exportSession cancelExport];
    [self finishExportStatus];
    
    if (_delegateFlag.didFail) {
        [self.delegate videoEditorController:self
                            didFailWithError:error];
    }
}

#pragma mark - notification

- (void) observeNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_pauseVideo:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_pauseVideo:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}

- (void) cancelObserveNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillTerminateNotification
                                                  object:nil];
}

#pragma mark - status

- (void) enterExportingStatus
{
    _isExperting = YES;
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.videoRangeSlider.enabled = NO;
    
    self.title = [self _internalTitle];
}

- (void) finishExportStatus
{
    _isExperting = NO;
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.navigationItem.leftBarButtonItem.enabled = YES;
    self.videoRangeSlider.enabled = YES;
    
    self.title = [self _internalTitle];
}

- (void) updateExpertProgress:(double)progress
{
    if (_isExperting) {
        self.title = [NSString stringWithFormat:@"%@ %.0f",[self _internalTitle],progress];
    }
}

#pragma mark - XCFAVPlayerViewDelegate

- (void) avPlayerViewDidPlayToEnd:(XCFAVPlayerView *)playerView
{
    [playerView pause];
    [playerView asyncSeekToSecond:self.currentRange.location completion:^(BOOL finish) {
        [playerView play];
    }];
}

- (void) avPlayerViewDidUpgradeProgress:(XCFAVPlayerView *)playerView
{
    NSTimeInterval end = XCFVideoRangeGetEnd(self.currentRange);
    if (playerView.progress < 1 && playerView.isPlaying && end > 0 && [playerView currentTime] >= end) {
        [self avPlayerViewDidPlayToEnd:playerView];
    }
}

@end

NSString *const XCFVideoEditorVideoInfoWidth = @"XCFVideoEditorVideoInfoWidth";
NSString *const XCFVideoEditorVideoInfoHeight = @"XCFVideoEditorVideoInfoHeight";
NSString *const XCFVideoEditorVideoInfoDuration = @"XCFVideoEditorVideoInfoDuration";
NSString *const XCFVideoEditorVideoInfoThumbnail = @"XCFVideoEditorVideoInfoThumbnail";

@interface XCFVideoEditorControllerDelegate : NSObject<XCFVideoEditorControllerDelegate>

@property (nonatomic, copy) void (^callback)(XCFVideoEditorController*,NSString*,NSDictionary*,NSError*);
@property (nonatomic, copy) void (^startExport)(XCFVideoEditorController *);

@end

@implementation XCFVideoEditorControllerDelegate

- (void) videoEditorDidStartExport:(XCFVideoEditorController *)editor
{
    if (self.startExport) {
        self.startExport(editor);
    }
}

- (void) videoEditorDidCancelEdit:(XCFVideoEditorController *)editor
{
    if (editor.navigationController.viewControllers.firstObject == editor) {
        [editor.navigationController dismissViewControllerAnimated:NO completion:nil];
    } else {
        [editor.navigationController popViewControllerAnimated:YES];
    }
}

- (void) videoEditorController:(XCFVideoEditorController *)editor didSaveEditedVideoToPath:(NSString *)editedVideoPath videoInfo:(NSDictionary *)videoInfo
{
    if (self.callback) {
        self.callback(editor,editedVideoPath,videoInfo,nil);
    }
}

- (void) videoEditorController:(XCFVideoEditorController *)editor didFailWithError:(NSError *)error
{
    if (self.callback) {
        self.callback(editor,nil,nil,error);
    }
}

@end

#import <objc/runtime.h>

@implementation XCFVideoEditorController (block)

- (XCFVideoEditorControllerDelegate *) _callbackHandler
{
    void *const key = _cmd;
    XCFVideoEditorControllerDelegate *delegate = objc_getAssociatedObject(self, key);
    if (!delegate) {
        delegate = [XCFVideoEditorControllerDelegate new];
        objc_setAssociatedObject(self, key, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return delegate;
}

+ (instancetype) videoEditorWithVideoFilePath:(NSString *)filePath
                                  startExport:(void (^)(XCFVideoEditorController *editor))startExportBlock
                                       output:(void (^)(XCFVideoEditorController *, NSString *, NSDictionary *, NSError *))outputBlock
{
    NSParameterAssert(filePath);
    XCFVideoEditorController *videoEditor = [[XCFVideoEditorController alloc] initWithVideoPath:filePath];
    
    if (outputBlock) {
        XCFVideoEditorControllerDelegate *delegate = [videoEditor _callbackHandler];
        delegate.callback = outputBlock;
        delegate.startExport = startExportBlock;
        videoEditor.delegate = delegate;
    }
    
    return videoEditor;
}

+ (instancetype) videoEditorWithVideoAsset:(AVAsset *)asset
                               startExport:(void (^)(XCFVideoEditorController *editor))startExportBlock
                                    output:(void (^)(XCFVideoEditorController *editor, NSString *editedFilePath, NSDictionary *info,NSError *error))outputBlock
{
    NSParameterAssert(asset);
    XCFVideoEditorController *videoEditor = [[XCFVideoEditorController alloc] initWithVideoAsset:asset];
    
    XCFVideoEditorControllerDelegate *delegate = [videoEditor _callbackHandler];
    delegate.callback = outputBlock;
    delegate.startExport = startExportBlock;
    videoEditor.delegate = delegate;
    
    return videoEditor;
}

@end

@implementation XCFVideoEditorController (XCF)

- (void) lockBarButtonItems
{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.navigationItem.leftBarButtonItem.enabled  = NO;
}

- (void) unlockBarButtonItems
{
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.navigationItem.leftBarButtonItem.enabled  = YES;
}

@end


