//
//  UIView+XCFAppearance.h
//  XCFKit
//
//  Created by Li Guoyin on 2016/10/31.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (XCFAppearance)

@property (assign, nonatomic) CGFloat xcf_cornerRadius UI_APPEARANCE_SELECTOR;
@property (assign, nonatomic) CGFloat xcf_borderWidth UI_APPEARANCE_SELECTOR;
@property (assign, nonatomic) UIColor *xcf_borderColor UI_APPEARANCE_SELECTOR;

@end
