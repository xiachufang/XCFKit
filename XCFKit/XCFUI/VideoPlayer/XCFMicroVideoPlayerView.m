//
//  XCFMicroVideoPlayerView.m
//  xcf-iphone
//
//  Created by Li Guoyin on 2016/12/15.
//  Copyright © 2016年 Xiachufang. All rights reserved.
//

#import "XCFMicroVideoPlayerView.h"
#import <ImageIO/CGImageProperties.h>
#import <CoreImage/CoreImage.h>
#import <GLKit/GLKView.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

@interface XCFMicroVideoPlayerView ()<XCFMicroVideoDecoderDelegate,GLKViewDelegate>

@property (nonatomic, strong) GLKView *glView;
@property (nonatomic, strong) CIContext *ciContext;
@property (nonatomic, strong) EAGLContext *eaglContext;
@property (nonatomic, strong) CIImage *previewCIImage;

@end

@implementation XCFMicroVideoPlayerView
{
    NSInteger _actualLoopCount;
    BOOL _running;
    
    CIImage *_currentImage;
    
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
    
    _previewCIImage = nil;
    _currentImage = nil;
    _ciContext = nil;
    
    if ([EAGLContext currentContext] == _eaglContext) {
        [EAGLContext setCurrentContext:nil];
        _eaglContext = nil;
    }
}

- (instancetype) initWithFrame:(CGRect)frame videoPath:(NSString *)path previewImage:(UIImage *)previewImage
{
    self = [super initWithFrame:frame];
    if (self) {
        _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        _eaglContext.multiThreaded = YES;
        
        _ciContext = [CIContext
                      contextWithEAGLContext:_eaglContext
                      options: @{kCIContextUseSoftwareRenderer: @NO}];
        
        _glView = [[GLKView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height) context:_eaglContext];
        _glView.enableSetNeedsDisplay = NO;
        _glView.delegate = self;
        _glView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
        _glView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_glView];
        
        if (path) {
            _decoder = [[XCFMicroVideoDecoder alloc] initWithVideoFilePath:path];
            _decoder.delegate = self;
        }
        
        if (previewImage) {
            _previewCIImage = [[CIImage alloc] initWithImage:previewImage];
            [self displayImage:_previewCIImage];
        }
        
        self.backgroundColor = [UIColor blackColor];
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
    CIImage *image = _currentImage ?: _previewCIImage;
    if (image) {
        return [[UIImage alloc] initWithCIImage:image];
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

+ (CIImage *) extractImageRefFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
                              frameOrientation:(XCFVideoFrameOrientation)orientation
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferRef pixelBuffer = imageBuffer;
    
    if (pixelBuffer) {
        CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        //CVPixelBufferRelease(pixelBuffer);
        uint32_t t = kCGImagePropertyOrientationUp;
        switch (orientation) {
            case XCFVideoFrameOrientationDown:
                t = kCGImagePropertyOrientationUp;
                break;
            case XCFVideoFrameOrientationLeft:
                t = kCGImagePropertyOrientationRight;
                break;
            case XCFVideoFrameOrientationRight:
                t = kCGImagePropertyOrientationLeft;
                break;
            default:
                break;
        }
        image = [image imageByApplyingOrientation:t];
        
        return image;
    } else {
        return nil;
    }
}

- (void) displayImage:(CIImage *)image
{
    [self displayImage:image transform:CGAffineTransformIdentity];
}

- (void) displayImage:(CIImage *)image transform:(CGAffineTransform)transform
{
    if (image) {
        _currentImage = image;
        
        // filters
        for (CIFilter *filter in self.filters) {
            [filter setValue:_currentImage forKey:kCIInputImageKey];
            _currentImage = filter.outputImage;
        }
        
        [_glView bindDrawable];
        
        if (_eaglContext != [EAGLContext currentContext]) {
            [EAGLContext setCurrentContext:_eaglContext];
        }
        
        glClearColor(0, 0, 0, 1);
        glClear(GL_COLOR_BUFFER_BIT);
        
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        
        CGSize imageSize = _currentImage.extent.size;
        CGFloat drawableWidth = _glView.drawableWidth;
        CGFloat drawableHeight = _glView.drawableHeight;
        
        CGRect drawFrame = CGRectMake(0, 0, drawableWidth, drawableHeight);
        
        CGFloat imageAR = imageSize.width / imageSize.height;
        CGFloat viewAR = drawFrame.size.width / drawFrame.size.height;
        if (imageAR > viewAR)
        {
            drawFrame.origin.y += (drawFrame.size.height - drawFrame.size.width / imageAR) / 2.0;
            drawFrame.size.height = drawFrame.size.width / imageAR;
        }
        else
        {
            drawFrame.origin.x += (drawFrame.size.width - drawFrame.size.height * imageAR) / 2.0;
            drawFrame.size.width = drawFrame.size.height * imageAR;
        }
        
        [_ciContext drawImage:_currentImage inRect:drawFrame fromRect:[_currentImage extent]];
        
        [_glView display];
    }
}

- (void) setPreviewImage:(UIImage *)previewImage
{
    _previewCIImage = nil;
    
    if (previewImage) {
        _previewCIImage = [[CIImage alloc] initWithImage:previewImage];
    }
    
    if (!_currentImage) {
        [self displayImage:_previewCIImage];
    }
}

#pragma mark - decoder

- (void) switchToVideoDecoder:(XCFMicroVideoDecoder *)decoder
{
    if (_decoder != decoder) {
        _running = NO;
        _decoder.delegate = nil;
        
        _decoder = decoder;
        _decoder.delegate = self;
        
        if (_decoder) {
            CGImageRef previewImageRef = [_decoder extractThumbnailImage];
            
            if (previewImageRef) {
                CIImage *previewImage = [[CIImage alloc] initWithCGImage:previewImageRef];
                [self displayImage:previewImage];
                
                CGImageRelease(previewImageRef);
            }
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
    
    if (_previewCIImage) {
        [self displayImage:_previewCIImage];
    } else {
        _currentImage = nil;
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
//    NSLog(@"%@ failed with error message : %@",decoder,error);
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
        CIImage *image = nil;
        if (_delegateFlag.displayBuffer) {
            image = [self.delegate microVideoPlayer:self
                            willDisplaySampleBuffer:buffer];
        } else if (buffer) {
            image = [self.class extractImageRefFromSampleBuffer:buffer
                                            frameOrientation:decoder.frameOrientation];
        }
        
        if (image) {
            [self displayImage:image];
            [self statusChanged];
        }
        
        if (_running) {
            [decoder requestNextSampleBuffer];
        }
    }
}

#pragma mark - GLKViewDelegate

- (void) glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // do nothing
}

@end
