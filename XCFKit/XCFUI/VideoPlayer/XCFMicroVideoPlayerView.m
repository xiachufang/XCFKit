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
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

@interface XCFMicroVideoPlayerView ()<XCFMicroVideoDecoderDelegate>

@property (nonatomic, strong) CIContext *coreImageContext;
@property (nonatomic, strong) CIImage *previewCIImage;

@end

@implementation XCFMicroVideoPlayerView
{
    NSInteger _actualLoopCount;
    BOOL _running;
    
    CIImage *_currentImage;
    CIImage *_renderImage;
    
    struct {
        unsigned int statusChanged : 1;
        unsigned int displayBuffer : 1;
    } _delegateFlag;
}

@dynamic delegate;

- (void) dealloc
{
    if (_decoder.delegate == self) {
        _decoder.delegate = nil;
    }
    
    _previewCIImage = nil;
    _currentImage = nil;
    _renderImage = nil;
}

- (instancetype) initWithFrame:(CGRect)frame videoPath:(NSString *)path previewImage:(UIImage *)previewImage
{
    EAGLContext *eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    eaglContext.multiThreaded = YES;
    
    self = [super initWithFrame:frame context:eaglContext];
    if (self) {
        _coreImageContext = [CIContext contextWithEAGLContext:eaglContext
                                                      options: @{kCIContextUseSoftwareRenderer: @NO}];
        
        self.enableSetNeedsDisplay = NO;
        
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

- (void) drawRect:(CGRect)rect
{
    if (_renderImage && self.drawableWidth > 0 && self.drawableHeight > 0) {
        CGRect destRect = [self drawFrameWithImageSize:_renderImage.extent.size];
        [_coreImageContext drawImage:_renderImage inRect:destRect fromRect:_renderImage.extent];
    }
}

- (void) setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self display];
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

- (void) setDelegate:(id<XCFMicroVideoPlayerViewDelegate,GLKViewDelegate>)delegate
{
    [super setDelegate:delegate];
    
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
    if (image) {
        _currentImage = image;
        _renderImage = _currentImage;
        
        // filters
        for (CIFilter *filter in self.filters) {
            [filter setValue:_renderImage forKey:kCIInputImageKey];
            _renderImage = filter.outputImage;
        }
        
        if (self.standardizationDrawRect) {
            _renderImage = [_renderImage imageByCroppingToRect:_currentImage.extent];
        }
        
        [self bindDrawable];
        
        if (self.context != [EAGLContext currentContext])
            [EAGLContext setCurrentContext:self.context];
        
        glClearColor(0.0, 0.0, 0.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
        
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        
        [self display];
    }
}

- (CGRect) drawFrameWithImageSize:(CGSize)imageSize
{
    CGFloat drawableWidth = self.drawableWidth;
    CGFloat drawableHeight = self.drawableHeight;
    CGRect drawFrame = CGRectMake(0, 0, drawableWidth, drawableHeight);
    
    CGFloat imageRatio = imageSize.width / imageSize.height;
    CGFloat drawRatio = (CGFloat)drawableWidth / drawableHeight;
    
    CGFloat x_padding = 0;
    CGFloat y_padding = 0;
    if (imageRatio > drawRatio) {
        if (self.fillWindow) {
            x_padding = (drawableWidth - (drawableHeight * imageRatio)) / 2;
        } else {
            y_padding = (drawableHeight - (drawableWidth / imageRatio)) / 2;
        }
    } else if (imageRatio < drawRatio) {
        if (self.fillWindow) {
            y_padding = (drawableHeight - (drawableWidth / imageRatio)) / 2;
        } else {
            x_padding = (drawableWidth - (drawableHeight * imageRatio)) / 2;
        }
    }
    
    return CGRectInset(drawFrame, x_padding, y_padding);
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

- (void) setFillWindow:(BOOL)fillWindow
{
    if (_fillWindow != fillWindow) {
        _fillWindow = fillWindow;
        
        if (!self.isPlaying && _currentImage) {
            [self displayImage:_currentImage];
        }
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

@end
