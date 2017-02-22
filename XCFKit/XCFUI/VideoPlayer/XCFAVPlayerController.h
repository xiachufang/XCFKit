//
//  XCFAVPlayerController.h
//  XCFKit
//
//  Created by Li Guoyin on 2016/12/19.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XCFVideoPlayerControlProtocol.h"

@class XCFAVPlayerController;

@protocol XCFAVPlayerControllerDelegate <NSObject>

@optional

- (void) avPlayerControllerDidCancel:(XCFAVPlayerController *)controller;
- (void) avPlayerControllerDidPlayToEnd:(XCFAVPlayerController *)controller;

@end

@interface XCFAVPlayerController : UIViewController<XCFVideoPlayerControlProtocol>

- (instancetype) initWithVideoFilePath:(NSString *)videoPath
                          previewImage:(UIImage *)previewImage
                 allowPlaybackControls:(BOOL)allowPlaybackControls;

- (instancetype) initWithVideoURL:(NSURL *)videoURL
                     previewImage:(UIImage *)previewImage
            allowPlaybackControls:(BOOL)allowPlaybackControls NS_DESIGNATED_INITIALIZER;

@property (nonatomic, weak) id<XCFAVPlayerControllerDelegate> delegate;

- (CGRect) videoRect;

#pragma mark - presentation animation

@property (nonatomic, weak) UIViewController *sourceController;
@property (nonatomic, weak) UIView *sourceView;  // souceview must be a child view of sourceController's view
@property (nonatomic, strong) UIImage *sourceImage;
@property (nonatomic, assign) UIViewContentMode sourceImageContentMode; // default is UIViewContentModeScaleAspectFit

@end
