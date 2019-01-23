//
//  UISearchBar+textField.m
//  XCFKit
//
//  Created by Li Guoyin on 2016/11/24.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import "UISearchBar+textField.h"

@implementation UISearchBar (textField)

- (UITextField *)xcf_textField {
    id textfield = [self valueForKey:@"_searchField"];
    if ([textfield isKindOfClass:[UITextField class]]) {
        return (UITextField *)textfield;
    }
    return nil;
}

@end
