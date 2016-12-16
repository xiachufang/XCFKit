//
//  XCFMicroVideoPlayerView.m
//  xcf-iphone
//
//  Created by Li Guoyin on 2016/12/15.
//  Copyright © 2016年 Xiachufang. All rights reserved.
//

#import "XCFMicroVideoPlayerView.h"

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
    return _decoder.videoURL.absoluteString;
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
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
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
    
    return imageRef;
}

- (void) displayImageRef:(CGImageRef)imageRef
{
    if (imageRef) {
        if (_currentImageRef && _currentImageRef != _previewImageRef) {
            CFRelease(_currentImageRef);
        }
        
        _currentImageRef = imageRef;
        [self.layer setContents:(__bridge id _Nullable)(imageRef)];
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
    }
}

#pragma mark - player control

- (void) play
{
    if (!_running && _decoder) {
        if ([_decoder nextSampleBufferAvaliable ]) {
            [_decoder requestNextSampleBuffer];
        } else {
            [_decoder prepareToStartDecode];
        }
        
        _running = YES;
        
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
    }
    
    [self statusChanged];
}

- (CGFloat) progress
{
    return [_decoder progress];
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
    if (decoder == _decoder) {
        NSLog(@"%@ is prepared to play video",decoder);
        [decoder requestNextSampleBuffer];
    }
}

- (void) microVideoDecoderDidFinishDecode:(XCFMicroVideoDecoder *)decoder
{
    if (decoder == _decoder) {
        _actualLoopCount += 1;
        
        NSLog(@"%@ finish decode with loop count : %zd",decoder,_actualLoopCount);
        
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
            ref = [self.class extractImageRefFromSampleBuffer:buffer];
        }
        
        if (ref) {
            [self displayImageRef:ref];
        }
        
        [decoder requestNextSampleBuffer];
    }
}

@end
