//
//  XCFMicroVideoPlayerView.h
//  xcf-iphone
//
//  Created by Li Guoyin on 2016/12/15.
//  Copyright © 2016年 Xiachufang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XCFMicroVideoDecoder.h"
#import "XCFVideoPlayerControlProtocol.h"
#import <GLKit/GLKView.h>

NS_ASSUME_NONNULL_BEGIN

@class XCFMicroVideoPlayerView,CIImage,CIFilter;

@protocol XCFMicroVideoPlayerViewDelegate <NSObject>

@optional

- (void) microVideoPlayerStatusChanged:(XCFMicroVideoPlayerView *)playerView;
- (CIImage *) microVideoPlayer:(XCFMicroVideoPlayerView *)playerView
        willDisplaySampleBuffer:(nullable CMSampleBufferRef)sampleBuffer;

@end

@interface XCFMicroVideoPlayerView : UIView<XCFVideoPlayerControlProtocol>

- (instancetype) initWithFrame:(CGRect)frame
                     videoPath:(nullable NSString *)path
                  previewImage:(nullable UIImage *)image;

@property (nonatomic, assign) NSInteger loopCount; // loopCount <= 0 表示无限循环播放
@property (nonatomic, copy, readonly) NSString *videoPath;

@property (nonatomic, assign) BOOL enableDebugMode;

@property (nonatomic, weak) id<XCFMicroVideoPlayerViewDelegate> delegate;

@property (nonatomic, assign) BOOL fillWindow; // default is NO, fit mode;

- (UIImage *) screenshot;

- (void) setPreviewImage:(UIImage *)previewImage;

@property (nonatomic, strong) NSArray<CIFilter *> *filters;
@property (nonatomic, assign) BOOL standardizationDrawRect; // default is YES

// decoder
@property (nonatomic, strong, readonly, nullable) XCFMicroVideoDecoder *decoder;

- (void) switchToVideoDecoder:(nullable XCFMicroVideoDecoder *)decoder;

@end

NS_ASSUME_NONNULL_END
