//
//  XCFMicroVideoPlayerView.m
//  xcf-iphone
//
//  Created by Li Guoyin on 2016/12/15.
//  Copyright © 2016年 Xiachufang. All rights reserved.
//

#import "XCFMicroVideoPlayerView.h"
#import <Accelerate/Accelerate.h>

@interface XCFMicroVideoPlayerView ()<XCFMicroVideoDecoderDelegate>

@property (nonatomic, assign) CGImageRef previewImageRef;

@end

@implementation XCFMicroVideoPlayerView
{
    NSInteger _actualLoopCount;
    BOOL _running;
    
    CGImageRef _currentImageRef;
    
    struct {
        unsigned int statusChanged : 1;
        unsigned int displayBuffer : 1;
    } _delegateFlag;
}

- (void) dealloc
{
    if (_decoder.delegate == self) {
        _decoder.delegate = nil;
    }
    
    _previewImageRef = nil;
    _currentImageRef = nil;
    self.layer.contents = nil;
}

- (instancetype) initWithFrame:(CGRect)frame videoPath:(NSString *)path previewImage:(UIImage *)image
{
    self = [super initWithFrame:frame];
    if (self) {
        if (path) {
            _decoder = [[XCFMicroVideoDecoder alloc] initWithVideoFilePath:path];
            _decoder.outputSize = frame.size;
            _decoder.delegate = self;
        }
        
        _currentImageRef = NULL;
        _previewImageRef = image.CGImage;
        [self displayImageRef:_previewImageRef];
        self.backgroundColor = [UIColor blackColor];
        
        self.layer.contentsGravity = kCAGravityResizeAspect;
        self.layer.masksToBounds = YES;
    }
    
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame
                     videoPath:nil
                  previewImage:nil];
}

- (NSString *) videoPath
{
    return _decoder.videoURL.path;
}

- (UIImage *) screenshot
{
    CGImageRef ref = _currentImageRef ?: _previewImageRef;
    if (ref) {
        return [[UIImage alloc] initWithCGImage:ref];
    } else {
        return nil;
    }
}

#pragma mark - delegate

- (void) setDelegate:(id<XCFMicroVideoPlayerViewDelegate>)delegate
{
    _delegate = delegate;
    
    _delegateFlag.statusChanged = [delegate respondsToSelector:@selector(microVideoPlayerStatusChanged:)];
    _delegateFlag.displayBuffer = [delegate respondsToSelector:@selector(microVideoPlayer:willDisplaySampleBuffer:)];
}

- (void) statusChanged // maybe
{
    if (_delegateFlag.statusChanged) {
        [self.delegate microVideoPlayerStatusChanged:self];
    }
}

#pragma mark - display

+ (CGImageRef) extractImageRefFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
                              frameOrientation:(XCFVideoFrameOrientation)orientation
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferRef rotatedBuffer = NULL;
    if (orientation != XCFVideoFrameOrientationUp)
    { // rotate image buffer
        CVPixelBufferLockBaseAddress(imageBuffer, 0);
        
        OSType pixelFormatType              = CVPixelBufferGetPixelFormatType(imageBuffer);
        
        const size_t kAlignment_32ARGB      = 32;
        const size_t kBytesPerPixel_32ARGB  = 4;
        
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width       = CVPixelBufferGetWidth(imageBuffer);
        size_t height      = CVPixelBufferGetHeight(imageBuffer);
        
        BOOL rotatePerpendicular = (orientation == XCFVideoFrameOrientationLeft) || (orientation == XCFVideoFrameOrientationRight);
        const size_t outWidth    = rotatePerpendicular ? height : width;
        const size_t outHeight   = rotatePerpendicular ? width  : height;
        
        size_t bytesPerRowOut    = kBytesPerPixel_32ARGB * ceil(outWidth * 1.0 / kAlignment_32ARGB) * kAlignment_32ARGB;
        const size_t dstSize     = bytesPerRowOut * outHeight * sizeof(unsigned char);
        void *srcBuff            = CVPixelBufferGetBaseAddress(imageBuffer);
        unsigned char *dstBuff   = (unsigned char *)malloc(dstSize);
        vImage_Buffer inbuff     = {srcBuff, height, width, bytesPerRow};
        vImage_Buffer outbuff    = {dstBuff, outHeight, outWidth, bytesPerRowOut};
        uint8_t bgColor[4]       = {1, 1, 1, 1};
        
        uint8_t rotationConstant = 0;
        switch (orientation) {
            case XCFVideoFrameOrientationRight: rotationConstant = 1;break;
            case XCFVideoFrameOrientationDown: rotationConstant = 2;break;
            case XCFVideoFrameOrientationLeft: rotationConstant = 3;break;
            default: rotationConstant = 0;break;
        }
        vImage_Error err = vImageRotate90_ARGB8888(&inbuff, &outbuff, rotationConstant, bgColor, 0);
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        
        if (err != kvImageNoError)
        {
            NSLog(@"%ld", err);
        } else {
            NSDictionary *pixelBufferAttributes = @{ (NSString *)kCVPixelBufferIOSurfacePropertiesKey : @{} };
            CVPixelBufferCreate(kCFAllocatorDefault,
                                outWidth,
                                outHeight,
                                pixelFormatType,
                                (__bridge CFDictionaryRef)(pixelBufferAttributes),
                                &rotatedBuffer);
            CVPixelBufferLockBaseAddress(rotatedBuffer, 0);
            uint8_t *dest = CVPixelBufferGetBaseAddress(rotatedBuffer);
            memcpy(dest, outbuff.data, bytesPerRowOut * outHeight);
            CVPixelBufferUnlockBaseAddress(rotatedBuffer, 0);
            
            free(dstBuff);
        }
    }
    
    if (rotatedBuffer) {
        imageBuffer = rotatedBuffer;
    }
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    uint8_t *base;
    size_t width, height, bytesPerRow;
    base = CVPixelBufferGetBaseAddress(imageBuffer);
    width = CVPixelBufferGetWidth(imageBuffer);
    height = CVPixelBufferGetHeight(imageBuffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    
    CGColorSpaceRef colorSpace;
    CGContextRef cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef imageRef = CGBitmapContextCreateImage(cgContext);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(cgContext);
    if (rotatedBuffer) {
        CFRelease(rotatedBuffer);
    }
    
    return imageRef;
}

- (void) displayImageRef:(CGImageRef)imageRef
{
    [self displayImageRef:imageRef transform:CGAffineTransformIdentity];
}

- (void) displayImageRef:(CGImageRef)imageRef transform:(CGAffineTransform)transform
{
    if (imageRef) {
        if (_currentImageRef && _currentImageRef != _previewImageRef) {
            CFRelease(_currentImageRef);
        }
        
        _currentImageRef = imageRef;
        [self.layer setContents:(__bridge id _Nullable)(imageRef)];
        
        self.layer.transform = CATransform3DMakeAffineTransform(transform);
    }
}

- (void) setPreviewImage:(UIImage *)previewImage
{
    if (_previewImageRef) {
        CGImageRelease(_previewImageRef);
    }
    
    _previewImageRef = [previewImage CGImage];
    
    if (!_currentImageRef) {
        [self displayImageRef:_previewImageRef];
    }
}

#pragma mark - decoder

- (void) switchToVideoDecoder:(XCFMicroVideoDecoder *)decoder
{
    if (_decoder != decoder) {
        _running = NO;
        _decoder.delegate = nil;
        
        _decoder = decoder;
        _decoder.outputSize = self.bounds.size;
        _decoder.delegate = self;
        
        if (_decoder) {
            _previewImageRef = [_decoder extractThumbnailImage];
            [self displayImageRef:_previewImageRef];
        }
    }
}

#pragma mark - player control

- (void) play
{
    if (!_running && _decoder) {
        _running = YES;
        
        if ([_decoder nextSampleBufferAvaliable ]) {
            [_decoder requestNextSampleBuffer];
        } else {
            [_decoder prepareToStartDecode];
        }
        
        [self statusChanged];
    }
}

- (void) pause
{
    if (_running) {
        _running = NO;
        
        [self statusChanged];
    }
}

- (void) stop
{
    [_decoder cleanup];
    _running = NO;
    _actualLoopCount = 0;
    
    if (_previewImageRef) {
        [self displayImageRef:_previewImageRef];
    } else {
        _currentImageRef = NULL;
        self.layer.contents = nil;
    }
    
    [self statusChanged];
}

- (CGFloat) progress
{
    return _decoder ? [_decoder progress] : -1;
}

- (BOOL) isPlaying
{
    return _running;
}

#pragma mark - XCFMicroVideoDecoderDelegate

- (void) microVideoDecoder:(XCFMicroVideoDecoder *)decoder decodeFailed:(NSError *)error
{
    NSLog(@"%@ failed with error message : %@",decoder,error.localizedDescription);
}

- (void) microVideoDecoderBePrepared:(XCFMicroVideoDecoder *)decoder
{
    if (decoder == _decoder && _running) {
        [decoder requestNextSampleBuffer];
    }
}

- (void) microVideoDecoderDidFinishDecode:(XCFMicroVideoDecoder *)decoder
{
    if (decoder == _decoder) {
        _actualLoopCount += 1;
        
        if (self.loopCount <= 0 || _actualLoopCount < self.loopCount) {
            [decoder prepareToStartDecode];
        }
    }
}

- (void) microVideoDecoder:(XCFMicroVideoDecoder *)decoder decodeNewSampleBuffer:(CMSampleBufferRef)buffer
{
    if (decoder == _decoder) {
        CGImageRef ref = NULL;
        if (_delegateFlag.displayBuffer) {
            ref = [self.delegate microVideoPlayer:self
                          willDisplaySampleBuffer:buffer];
        } else if (buffer) {
            ref = [self.class extractImageRefFromSampleBuffer:buffer
                                            frameOrientation:decoder.frameOrientation];
        }
        
        if (ref) {
            [self displayImageRef:ref];
            [self statusChanged];
        }
        
        if (_running) {
            [decoder requestNextSampleBuffer];
        }
    }
}

@end
