//
//  XCFVideoEditorController.h
//  XCFKit
//
//  Created by Li Guoyin on 2017/1/4.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol XCFVideoEditorControllerDelegate;

@interface XCFVideoEditorController : UIViewController

+ (BOOL)canEditVideoAtPath:(NSString *)videoPath;

- (instancetype) initWithVideoPath:(NSString *)videoPath;

@property (nonatomic, weak) id<XCFVideoEditorControllerDelegate> delegate;

@property (nonatomic, assign) NSTimeInterval videoMaximumDuration; // default is 15 s
@property (nonatomic, assign) NSTimeInterval videoMinimumDuration; // default is 3 s

// video quality
// xxxxx

@end

@protocol XCFVideoEditorControllerDelegate <NSObject>

@optional



@end
