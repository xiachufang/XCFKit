//
//  XCFVideoPlayerProtocol.h
//  xcf-iphone
//
//  Created by Li Guoyin on 2016/12/15.
//  Copyright © 2016年 Xiachufang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol XCFVideoPlayerControlProtocol <NSObject>

- (void)play;
- (void)pause;
- (void)stop;

- (BOOL)isPlaying;
- (CGFloat)progress;

@end
