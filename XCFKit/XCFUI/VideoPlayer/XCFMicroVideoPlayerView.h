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

NS_ASSUME_NONNULL_BEGIN

@class XCFMicroVideoPlayerView;

@protocol XCFMicroVideoPlayerViewDelegate <NSObject>

@optional

- (void) microVideoPlayerStatusChanged:(XCFMicroVideoPlayerView *)playerView;
- (CGImageRef) microVideoPlayer:(XCFMicroVideoPlayerView *)playerView
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

- (UIImage *) screenshot;

- (void) setPreviewImage:(UIImage *)previewImage;
- (void) renderImage:(UIImage *)image;

- (NSTimeInterval) playTime;

// decoder
@property (nonatomic, strong, readonly, nullable) XCFMicroVideoDecoder *decoder;

- (void) switchToVideoDecoder:(nullable XCFMicroVideoDecoder *)decoder;

@end

NS_ASSUME_NONNULL_END
