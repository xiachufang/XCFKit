//
//  XCFMicroVideoDecoder.h
//  xcf-iphone
//
//  Created by Li Guoyin on 2016/12/15.
//  Copyright © 2016年 Xiachufang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class XCFMicroVideoDecoder;

enum {
    XCFMicroVideoDecoderErrorVideoNotFound = 404,
    XCFMicroVideoDecoderErrorTrackLoadFailed = 405,
};

@protocol XCFMicroVideoDecoderDelegate <NSObject>

@optional

- (void) microVideoDecoder:(XCFMicroVideoDecoder *)decoder decodeFailed:(NSError *)error;
- (void) microVideoDecoderBePrepared:(XCFMicroVideoDecoder *)decoder;
- (void) microVideoDecoderDidFinishDecode:(XCFMicroVideoDecoder *)decoder;
- (void) microVideoDecoder:(XCFMicroVideoDecoder *)decoder decodeNewSampleBuffer:(nullable CMSampleBufferRef)buffer;

@end

typedef enum : NSUInteger {
    XCFVideoFrameOrientationUp,
    XCFVideoFrameOrientationLeft,
    XCFVideoFrameOrientationRight,
    XCFVideoFrameOrientationDown
} XCFVideoFrameOrientation;

@interface XCFMicroVideoDecoder : NSObject

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithVideoAsset:(AVURLAsset *)asset NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithVideoFilePath:(NSString *)videoFilePath;

@property (nonatomic, weak, nullable) id<XCFMicroVideoDecoderDelegate> delegate;

@property (nonatomic, copy, readonly) NSURL *videoURL;

@property (nonatomic, strong, readonly, nullable) AVAssetReader *assetReader;

// if decoder is not prepared or failed, progress will be -1, otherwise progress = [0,1]
@property (nonatomic, assign, readonly) CGFloat progress;

/*
 *  `outputSize` 默认是 CGSizeZero，导出媒体文件原本的尺寸
 *   在 prepareToStartDecode 前设置生效
 */
@property (nonatomic, assign) CGSize outputSize;

@property (nonatomic, readonly) XCFVideoFrameOrientation frameOrientation;
@property (nonatomic, readonly) CGAffineTransform preferredTransform;

- (void) prepareToStartDecode;

- (BOOL) nextSampleBufferAvaliable;
- (void) requestNextSampleBuffer;

- (void) cleanup;

- (nullable CGImageRef) extractThumbnailImage;

@end

NS_ASSUME_NONNULL_END
