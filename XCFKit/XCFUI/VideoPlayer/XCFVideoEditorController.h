//
//  XCFVideoEditorController.h
//  XCFKit
//
//  Created by Li Guoyin on 2017/1/4.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol XCFVideoEditorControllerDelegate;

@class AVAsset;

typedef NS_ENUM(NSInteger, XCFVideoEditorVideoQualityType) {
    XCFVideoEditorVideoQualityTypeLow    = 1 << 0,
    XCFVideoEditorVideoQualityTypeMedium = 1 << 1,
    XCFVideoEditorVideoQualityTypeHigh   = 1 << 2,
    
    XCFVideoEditorVideoQualityType1x1    = 0 << 4,
    XCFVideoEditorVideoQualityType4x3    = 1 << 4,
    XCFVideoEditorVideoQualityType5x4    = 2 << 5,
};

@interface XCFVideoEditorController : UIViewController

+ (BOOL) canEditVideoAtPath:(NSString *)videoPath;
+ (void) loadVideoAssetAtPath:(NSString *)videoPath
                   completion:(void (^)(AVAsset *asset,NSError *error))completion;

- (instancetype) initWithVideoPath:(NSString *)videoPath;
- (instancetype) initWithVideoAsset:(AVAsset *)asset;

@property (nonatomic, weak) id<XCFVideoEditorControllerDelegate> delegate;

@property (nonatomic, assign) NSTimeInterval videoMaximumDuration; // default is 10 s
@property (nonatomic, assign) NSTimeInterval videoMinimumDuration; // default is 3 s

// video quality , default is XCFVideoEditorVideoQualityTypeMedium | XCFVideoEditorVideoQualityType1x1
@property (nonatomic, assign) XCFVideoEditorVideoQualityType videoQuality;

@end

@protocol XCFVideoEditorControllerDelegate <NSObject>

@optional

- (void) videoEditorDidStartExport:(XCFVideoEditorController *)editor;
- (void) videoEditorDidCancelEdit:(XCFVideoEditorController *)editor;

// videoInfo 包含的值有 XCFVideoEditorVideoInfoWidth XCFVideoEditorVideoInfoHeight
// XCFVideoEditorVideoInfoDuration ， 正常情况下有 XCFVideoEditorVideoInfoThumbnail 但不保证
- (void)videoEditorController:(XCFVideoEditorController *)editor
     didSaveEditedVideoToPath:(NSString *)editedVideoPath
                    videoInfo:(NSDictionary *)videoInfo;

- (void)videoEditorController:(XCFVideoEditorController *)editor
             didFailWithError:(NSError *)error;

@end

extern NSString *const XCFVideoEditorVideoInfoWidth;
extern NSString *const XCFVideoEditorVideoInfoHeight;
extern NSString *const XCFVideoEditorVideoInfoDuration;
extern NSString *const XCFVideoEditorVideoInfoThumbnail;

@interface XCFVideoEditorController (block)

// 注意，采用 block 回调的形式就不要再设置 delegate
+ (instancetype) videoEditorWithVideoFilePath:(NSString *)filePath
                                  startExport:(void (^)(XCFVideoEditorController *editor))startExportBlock
                                       output:(void (^)(XCFVideoEditorController *editor, NSString *editedFilePath, NSDictionary *info,NSError *error))outputBlock;

+ (instancetype) videoEditorWithVideoAsset:(AVAsset *)asset
                               startExport:(void (^)(XCFVideoEditorController *editor))startExportBlock
                                    output:(void (^)(XCFVideoEditorController *editor, NSString *editedFilePath, NSDictionary *info,NSError *error))outputBlock;

@end
