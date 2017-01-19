//
//  XCFMicroVideoDecoder.m
//  xcf-iphone
//
//  Created by Li Guoyin on 2016/12/15.
//  Copyright © 2016年 Xiachufang. All rights reserved.
//

#import "XCFMicroVideoDecoder.h"

#import <libkern/OSAtomic.h>

#define XCFMicroDecoderErrorDomin @"com.xiachufang.videoDecoder"
#define XCFMicroDecoderInvalidProgress (-1)

@interface XCFMicroVideoDecoder ()

@property (nonatomic, strong) AVURLAsset *videoAsset;

@property (nonatomic, strong, readwrite) AVAssetReader *assetReader;
@property (nonatomic, strong) AVAssetReaderTrackOutput *assetOutput;

@property (nonatomic, strong) AVAssetImageGenerator *imageGenerator;

@end

@implementation XCFMicroVideoDecoder
{
    @private
    struct {
        unsigned int didFail   : 1;
        unsigned int prepared  : 1;
        unsigned int finished  : 1;
        unsigned int newBuffer : 1;
    } _delegateFlag;
    
    BOOL _assetLoaded;
    uint32_t _assetLoadLock;
    
    // 目前处理的 frame 所在的时间
    CMTime _decodingFrameTime;
    
    // 上一帧的时间
    CMTime _previousFrameTime;
    CFAbsoluteTime _previousFrameActualTime;
    
    // 用来取 buffer 的 serial 线程
    dispatch_queue_t _serialQueue;
}

#pragma mark - lifetime

- (void) dealloc
{
    [self cleanup];
}

- (instancetype) init
{
    NSParameterAssert(NO);
    return [self initWithVideoFilePath:@""];
}

- (instancetype) initWithVideoFilePath:(NSString *)videoFilePath
{
    NSURL *url = [NSURL fileURLWithPath:videoFilePath];
    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey : @(YES)};
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url
                                                options:options];
    return [self initWithVideoAsset:asset];
}

- (instancetype) initWithVideoAsset:(AVURLAsset *)asset
{
    NSParameterAssert(asset);
    
    self = [super init];
    if (self) {
        _videoAsset = asset;
        
        _assetLoaded = NO;
        _assetLoadLock = 0;
        
        _decodingFrameTime = kCMTimeZero;
        _previousFrameTime = kCMTimeZero;
        _previousFrameActualTime = 0;
        
        NSString *queueName = [NSString stringWithFormat:@"com.xiachufang.videoDecoder-%@-serialQueue",[[NSUUID UUID] UUIDString]];
        _serialQueue = dispatch_queue_create([queueName cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

#pragma mark - delegate

- (void) setDelegate:(id<XCFMicroVideoDecoderDelegate>)delegate
{
    _delegate = delegate;
    
    _delegateFlag.didFail = [delegate respondsToSelector:@selector(microVideoDecoder:decodeFailed:)];
    _delegateFlag.prepared = [delegate respondsToSelector:@selector(microVideoDecoderBePrepared:)];
    _delegateFlag.finished = [delegate respondsToSelector:@selector(microVideoDecoderDidFinishDecode:)];
    _delegateFlag.newBuffer = [delegate respondsToSelector:@selector(microVideoDecoder:decodeNewSampleBuffer:)];
}

- (void) safelyNotificateDelegateWithBlock:(void (^)())block
{
    if (!block) return;
    
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

- (void) detectError:(NSError *)error
{
    __weak typeof(self) weak_self = self;
    void (^block)() = ^{
        __strong typeof(weak_self) strong_self = weak_self;
        if (!strong_self) return;
        
        if (strong_self->_delegateFlag.didFail) {
            [strong_self.delegate microVideoDecoder:strong_self decodeFailed:error];
        }
    };
    
    [self safelyNotificateDelegateWithBlock:block];
}

- (void) prepareDone
{
    __weak typeof(self) weak_self = self;
    void (^block)() = ^{
        __strong typeof(weak_self) strong_self = weak_self;
        if (!strong_self) return;
        
        if (strong_self->_delegateFlag.prepared) {
            [strong_self.delegate microVideoDecoderBePrepared:strong_self];
        }
    };
    
    // 开始进入 reading 状态
    [self.assetReader startReading];
    
    // 通知 delegate
    [self safelyNotificateDelegateWithBlock:block];
}

- (void) decodeComplete
{
    __weak typeof(self) weak_self = self;
    void (^block)() = ^{
        __strong typeof(weak_self) strong_self = weak_self;
        if (!strong_self) return;
        
        if (strong_self->_delegateFlag.finished) {
            [strong_self.delegate microVideoDecoderDidFinishDecode:strong_self];
        }
    };
    
    // 结束 read
    [self.assetReader cancelReading];
    
    // 通知 delegate
    [self safelyNotificateDelegateWithBlock:block];
}

#pragma mark - getter

- (NSURL *) videoURL
{
    return [self.videoAsset URL];
}

- (CGFloat) progress
{
    switch (self.assetReader.status) {
        case AVAssetReaderStatusUnknown:
        case AVAssetReaderStatusFailed:
        case AVAssetReaderStatusCancelled: return XCFMicroDecoderInvalidProgress;
        case AVAssetReaderStatusReading: {
            return CMTimeGetSeconds(_decodingFrameTime) / CMTimeGetSeconds(self.videoAsset.duration);
        }
        case AVAssetReaderStatusCompleted: return 1;
    }
}

- (CGAffineTransform) preferredTransform
{
    return self.assetOutput.track ? self.assetOutput.track.preferredTransform : CGAffineTransformIdentity;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"%@<%p> url:%@ progress:%.2f",self.class,self,self.videoURL.absoluteString,self.progress];
}

#pragma mark - decode

- (BOOL) createAssetReader
{
    NSError *error = nil;
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:self.videoAsset
                                                          error:&error];
    AVAssetTrack *videoTrack = [self.videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    
    if (!videoTrack || error || videoTrack.nominalFrameRate == 0) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"初始化 AssetReader 失败"};
        error = [NSError errorWithDomain:XCFMicroDecoderErrorDomin
                                    code:XCFMicroVideoDecoderErrorVideoNotFound
                                userInfo:userInfo];
        [self detectError:error];
        return NO;
    }
    
    CGAffineTransform t = videoTrack.preferredTransform;
    if (t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0) {
        _frameOrientation = XCFVideoFrameOrientationLeft;
    } else if (t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0) {
        _frameOrientation = XCFVideoFrameOrientationRight;
    } else if (t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0) {
        _frameOrientation = XCFVideoFrameOrientationUp;
    } else if (t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0) {
        _frameOrientation = XCFVideoFrameOrientationDown;
    }
    
    CGSize outputSize = videoTrack.naturalSize;
    if (videoTrack.naturalSize.width > 0 && !CGSizeEqualToSize(self.outputSize, CGSizeZero)) {
        CGFloat actualRatio = videoTrack.naturalSize.height / videoTrack.naturalSize.width;
        
        CGFloat outputWidth = self.outputSize.width;
        if (_frameOrientation == XCFVideoFrameOrientationLeft ||
            _frameOrientation == XCFVideoFrameOrientationRight) {
            outputWidth = self.outputSize.height;
        }
        
        if (outputWidth < videoTrack.naturalSize.width) {
            outputSize = CGSizeMake(outputWidth, outputWidth * actualRatio);
        }
    }
    
    NSDictionary *outputSettings =
  @{(id)kCVPixelBufferWidthKey:@(outputSize.width),
    (id)kCVPixelBufferHeightKey:@(outputSize.height),
    (id)kCVPixelBufferPixelFormatTypeKey:@((int)kCVPixelFormatType_32BGRA)};
    
    AVAssetReaderTrackOutput *readerVideoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack outputSettings:outputSettings];
    readerVideoTrackOutput.alwaysCopiesSampleData = NO;
    [reader addOutput:readerVideoTrackOutput];
    
    self.assetReader = reader;
    self.assetOutput = readerVideoTrackOutput;
    
    return YES;
}

- (void) prepareToStartDecode
{
    if (!self->_assetLoaded) {
        
        // load asset
        if (OSAtomicTestAndSet(1, &_assetLoadLock)) return;
        
        __weak typeof(self) weak_self = self;
        NSString *loadKey = @"tracks";
        [self.videoAsset loadValuesAsynchronouslyForKeys:@[loadKey] completionHandler:^{
            __strong typeof(weak_self) strong_self = weak_self;
            if (!strong_self) return;
            
            NSError *error = nil;
            AVKeyValueStatus trackStatus = [strong_self.videoAsset statusOfValueForKey:loadKey
                                                                          error:&error];
            if (trackStatus != AVKeyValueStatusLoaded) {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"加载 Tracks 失败"};
                error = [NSError errorWithDomain:XCFMicroDecoderErrorDomin
                                            code:XCFMicroVideoDecoderErrorTrackLoadFailed
                                        userInfo:userInfo];
                [strong_self detectError:error];
                goto exit;
            }
            
            if([strong_self createAssetReader]) {
                strong_self->_assetLoaded = YES;
                [strong_self prepareDone];
            }
            
        exit:
            OSAtomicTestAndClear(1, &strong_self->_assetLoadLock);
        }];
    } else if (self.progress == XCFMicroDecoderInvalidProgress ||
               self.assetReader.status == AVAssetReaderStatusCompleted) {
        [self cleanup];
        if([self createAssetReader]) {
            [self prepareDone];
        }
    }
}

- (void) cleanup
{
    [_assetReader cancelReading];
    _assetReader = nil;
    _assetOutput = nil;
    
    _decodingFrameTime = kCMTimeZero;
    _previousFrameTime = kCMTimeZero;
    _previousFrameActualTime = 0;
    
    _frameOrientation = XCFVideoFrameOrientationUp;
}

- (BOOL) nextSampleBufferAvaliable
{
    return self.assetReader.status == AVAssetReaderStatusReading;
}

- (void) requestNextSampleBuffer
{
    if (self.assetReader.status == AVAssetReaderStatusReading) {
        __weak typeof(self) weak_self = self;
        dispatch_async(self->_serialQueue, ^{
            __strong typeof(weak_self) strong_self = weak_self;
            if (!strong_self || strong_self.assetReader.status != AVAssetReaderStatusReading) return;
            
            if (CMTimeCompare(strong_self->_previousFrameTime, kCMTimeZero) == 0) {
                strong_self->_previousFrameActualTime = CFAbsoluteTimeGetCurrent();
            }
            
            CMSampleBufferRef sampleBuffer = [strong_self.assetOutput copyNextSampleBuffer];
            
            if (sampleBuffer) {
                CMTime sampleBufferTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
                CMTime differenceBetweenLastFrame = CMTimeSubtract(sampleBufferTime, strong_self->_previousFrameTime);
                Float64 differenceInSeconds = CMTimeGetSeconds(differenceBetweenLastFrame);
                CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
                CFAbsoluteTime actualDifference = currentTime - strong_self->_previousFrameActualTime;
                
                if (differenceInSeconds > actualDifference) {
                    usleep(1000000.0 * (differenceInSeconds - actualDifference));
                }
                
                if (!strong_self) return;
                strong_self->_previousFrameTime = sampleBufferTime;
                strong_self->_previousFrameActualTime = CFAbsoluteTimeGetCurrent();
                
                strong_self->_decodingFrameTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if (strong_self->_delegateFlag.newBuffer) {
                        [strong_self.delegate microVideoDecoder:strong_self
                                          decodeNewSampleBuffer:sampleBuffer];
                    }
                });
                
                CMSampleBufferInvalidate(sampleBuffer);
                CFRelease(sampleBuffer);
                sampleBuffer = NULL;
            } else {
                if (self->_delegateFlag.newBuffer) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        __strong typeof(weak_self) strong_self = weak_self;
                        if (!strong_self) return;
                        [strong_self.delegate microVideoDecoder:strong_self
                                   decodeNewSampleBuffer:nil];
                    });
                }
            }
        });
    } else if (self.assetReader.status == AVAssetReaderStatusCompleted) {
        [self decodeComplete];
    } else if (self.assetReader.status == AVAssetReaderStatusFailed) {
        [self detectError:self.assetReader.error];
    }
}

- (CGImageRef) extractThumbnailImage
{
    if (!_videoAsset) return NULL;
    
    if (!_imageGenerator) {
        _imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:_videoAsset];
        _imageGenerator.appliesPreferredTrackTransform = self;
    }
    
    CGImageRef imageRef = [_imageGenerator copyCGImageAtTime:kCMTimeZero
                                                  actualTime:NULL
                                                       error:NULL];
    return imageRef;
}

@end
