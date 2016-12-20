//
//  XCFAVPlayerController.h
//  XCFKit
//
//  Created by Li Guoyin on 2016/12/19.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XCFAVPlayerController : UIViewController

- (instancetype) initWithVideoPath:(NSString *)videoPath previewImage:(UIImage *)previewImage NS_DESIGNATED_INITIALIZER;

#pragma mark - presentation animation

@property (nonatomic, weak) UIViewController *sourceController;
@property (nonatomic, weak) UIView *sourceView;  // souceview must be a child view of sourceController's view
@property (nonatomic, strong) UIImage *sourceImage;

@end
