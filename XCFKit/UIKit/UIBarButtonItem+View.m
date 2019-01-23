//
//  UIBarButtonItem+View.m
//  XCFKit
//
//  Created by Li Guoyin on 2016/11/7.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import "UIBarButtonItem+View.h"

@implementation UIBarButtonItem (View)

/*
 * 这种比较 hack 的方式虽然不是 100% 保险，但是被苹果重构掉的可能性很小
 */
- (UIView *)xcf_getView {
    return [self valueForKey:@"_view"];
}

@end
