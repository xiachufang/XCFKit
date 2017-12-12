//
//  XCFAppearanceColorCell.m
//  XCFKit iOS Demo
//
//  Created by Li Guoyin on 2017/12/12.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import "XCFAppearanceColorCell.h"

@implementation XCFAppearanceColorCell

- (void) setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    CGFloat scale = highlighted ? 0.9 : 1;
    CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);
    
    [UIView animateWithDuration:0.25
                          delay:0
         usingSpringWithDamping:10
          initialSpringVelocity:20
                        options:0
                     animations:^{
                         self.transform = transform;
                     } completion:nil];
}

@end
