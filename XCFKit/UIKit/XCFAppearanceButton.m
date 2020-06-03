//
//  XCFAppearanceButton.m
//  XCFKit
//
//  Created by Li Guoyin on 2016/10/28.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import "XCFAppearanceButton.h"
#import "UIColor+Hex.h"
#import "UIColor+XCFAppearance.h"
#import "UIFont+XCFAppearance.h"
#import "UIImage+PureColor.h"
#import "UIView+XCFAppearance.h"

@implementation UIButton (XCFAppearance)

//+ (void)load {
//    [[UILabel appearanceWhenContainedIn:[XCFAppearanceButtonA class], [XCFAppearanceButtonB class], nil]
//        setFont:[UIFont xcf_buttonFont]];
//
//    // XCFAppearanceButtonA
//    [[XCFAppearanceButtonA appearance] setTitleColor:[UIColor whiteColor]
//                                            forState:UIControlStateNormal];
//    [[XCFAppearanceButtonA appearance] setBackgroundImage:[UIImage xcf_mainButtonNormalBackgroundImage]
//                                                 forState:UIControlStateNormal];
//    [[XCFAppearanceButtonA appearance] setBackgroundImage:[UIImage xcf_mainButtonSelectedBackgroundImage]
//                                                 forState:UIControlStateSelected];
//
//    // XCFAppearanceButtonB
//    [[XCFAppearanceButtonB appearance] setTitleColor:[UIColor xcf_linkColor]
//                                            forState:UIControlStateNormal];
//    [[XCFAppearanceButtonB appearance] setBackgroundImage:[UIImage xcf_buttonBHighlightedBackgroundImage]
//                                                 forState:UIControlStateHighlighted];
//    [[XCFAppearanceButtonB appearance] setBackgroundImage:[UIImage xcf_buttonBHighlightedBackgroundImage]
//                                                 forState:UIControlStateSelected | UIControlStateHighlighted];
//    [[XCFAppearanceButtonB appearance] setTitleColor:[UIColor xcf_grayColor]
//                                            forState:UIControlStateDisabled];
//    [[XCFAppearanceButtonB appearance] setXcf_borderColor:[UIColor xcf_linkColor]];
//    [[XCFAppearanceButtonB appearance] setXcf_borderWidth:1];
//
//    // XCFAppearanceButtonC
//    [[XCFAppearanceButtonC appearance] setTitleColor:[UIColor xcf_linkColor]
//                                            forState:UIControlStateNormal];
//
//    // XCFAppearanceButtonD
//    [[XCFAppearanceButtonD appearance] setTitleColor:[UIColor xcf_supplementaryTextColor]
//                                            forState:UIControlStateNormal];
//    [[XCFAppearanceButtonF appearance] setXcf_borderColor:[UIColor xcf_supplementaryTextColor]];
//    [[XCFAppearanceButtonF appearance] setXcf_borderWidth:1];
//
//    //XCFAppearanceButtonE
//    [[XCFAppearanceButtonE appearance] setBackgroundImage:[UIImage xcf_buttonENormalBackgroundImage] forState:UIControlStateNormal];
//    [[XCFAppearanceButtonE appearance] setBackgroundImage:[UIImage xcf_buttonEHighlightedBackgroundImage] forState:UIControlStateSelected | UIControlStateHighlighted];
//    [[XCFAppearanceButtonE appearance] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//
//    //XCFAppearanceButtonG
//    [[XCFAppearanceButtonG appearance] setTitleColor:[UIColor xcf_yellowTextColor] forState:UIControlStateNormal];
//    [[XCFAppearanceButtonG appearance] setXcf_borderColor:[UIColor xcf_yellowTextColor]];
//    [[XCFAppearanceButtonG appearance] setXcf_borderWidth:1];
//
//    // XCFAppearanceButtonH
//    [[XCFAppearanceButtonH appearance] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [[XCFAppearanceButtonH appearance] setBackgroundImage:[UIImage xcf_buttonHNormalBackgroundImage] forState:UIControlStateNormal];
//    [[XCFAppearanceButtonH appearance] setBackgroundImage:[UIImage xcf_buttonHHighlightedBackgroundImage] forState:UIControlStateHighlighted];
//
//    // XCFAppearanceButtonI
//    [[XCFAppearanceButtonI appearance] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [[XCFAppearanceButtonI appearance] setBackgroundImage:[UIImage xcf_buttonINormalBackgroundImage] forState:UIControlStateNormal];
//    [[XCFAppearanceButtonI appearance] setBackgroundImage:[UIImage xcf_buttonIHighlightedBackgroundImage] forState:UIControlStateHighlighted];
//
//    // XCFAppearanceButtonA
//    [[XCFAppearanceButtonJ appearance] setTitleColor:[UIColor whiteColor]
//                                            forState:UIControlStateNormal];
//    [[XCFAppearanceButtonJ appearance] setBackgroundImage:[UIImage xcf_buttonJNormalBackgroundImage]
//                                                 forState:UIControlStateNormal];
//    [[XCFAppearanceButtonA appearance] setBackgroundImage:[UIImage xcf_buttonJHighlightedBackgroundImage]
//                                                 forState:UIControlStateSelected];
//}

//- (void)xcf_applyStyle:(XCFAppearanceButtonStyle)style {
//    self.layer.masksToBounds = YES;
//
//    switch (style) {
//        case XCFAppearanceButtonStyleA: {
//            [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//            [self setBackgroundImage:[UIImage xcf_mainButtonNormalBackgroundImage]
//                            forState:UIControlStateNormal];
//            [self setBackgroundImage:[UIImage xcf_mainButtonSelectedBackgroundImage]
//                            forState:UIControlStateSelected];
//        }
//            break;
//            
//        case XCFAppearanceButtonStyleB: {
//            [self setTitleColor:[UIColor xcf_linkColor]
//                       forState:UIControlStateNormal];
//            [self setBackgroundImage:[UIImage xcf_buttonBHighlightedBackgroundImage]
//                            forState:UIControlStateHighlighted];
//            [self setBackgroundImage:[UIImage xcf_buttonBHighlightedBackgroundImage]
//                            forState:UIControlStateSelected | UIControlStateHighlighted];
//            [self setTitleColor:[UIColor xcf_grayColor]
//                       forState:UIControlStateDisabled];
//            self.layer.borderColor = [UIColor xcf_linkColor].CGColor;
//            self.layer.borderWidth = 1;
//        }
//            break;
//            
//        case XCFAppearanceButtonStyleC: {
//            [self setTitleColor:[UIColor xcf_linkColor] forState:UIControlStateNormal];
//        }
//            break;
//            
//        case XCFAppearanceButtonStyleF: {
//            self.layer.borderColor = [UIColor xcf_supplementaryTextColor].CGColor;
//            self.layer.borderWidth = 1;
//        }
//            // 这里没有漏掉 break ，F 是继承于 D 的。
//        case XCFAppearanceButtonStyleD: { // 从代码上看 F 和 D 没有区别
//            [self setTitleColor:[UIColor xcf_supplementaryTextColor] forState:UIControlStateNormal];
//        }
//            break;
//            
//        case XCFAppearanceButtonStyleE: {
//            [self setBackgroundImage:[UIImage xcf_buttonENormalBackgroundImage] forState:UIControlStateNormal];
//            [self setBackgroundImage:[UIImage xcf_buttonEHighlightedBackgroundImage] forState:UIControlStateSelected | UIControlStateHighlighted];
//            [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//        }
//            break;
//            
//        case XCFAppearanceButtonStyleG: {
//            [self setTitleColor:[UIColor xcf_yellowTextColor] forState:UIControlStateNormal];
//            self.layer.borderColor = [UIColor xcf_yellowTextColor].CGColor;
//            self.layer.borderWidth = 1;
//        }
//            break;
//            
//        case XCFAppearanceButtonStyleH: {
//            [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//            [self setBackgroundImage:[UIImage xcf_buttonHNormalBackgroundImage] forState:UIControlStateNormal];
//            [self setBackgroundImage:[UIImage xcf_buttonHHighlightedBackgroundImage] forState:UIControlStateHighlighted];
//        }
//            break;
//            
//        case XCFAppearanceButtonStyleI: {
//            [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//            [self setBackgroundImage:[UIImage xcf_buttonINormalBackgroundImage] forState:UIControlStateNormal];
//            [self setBackgroundImage:[UIImage xcf_buttonIHighlightedBackgroundImage] forState:UIControlStateHighlighted];
//        }
//            break;
//            
//        case XCFAppearanceButtonStyleJ: {
//            [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//            [self setBackgroundImage:[UIImage xcf_buttonJNormalBackgroundImage] forState:UIControlStateNormal];
//            [self setBackgroundImage:[UIImage xcf_buttonJHighlightedBackgroundImage] forState:UIControlStateHighlighted];
//        }
//            break;
//            
//        default:
//            break;
//    }
//}

@end

@implementation UIImage (XCFAppearanceButton)

//+ (instancetype)xcf_mainButtonNormalBackgroundImage {
//    UIColor *color = [UIColor xcf_linkColor];
//    return [UIImage xcf_imageWithColor:color];
//}
//
//+ (instancetype)xcf_mainButtonSelectedBackgroundImage {
//    UIColor *color = [UIColor xcf_selectedButtonColor];
//    return [UIImage xcf_imageWithColor:color];
//}
//
//+ (instancetype)xcf_buttonBHighlightedBackgroundImage {
//    UIColor *color = [[UIColor xcf_linkColor] colorWithAlphaComponent:0.5];
//    return [UIImage xcf_imageWithColor:color];
//}
//
//+ (instancetype)xcf_buttonENormalBackgroundImage {
//    UIColor *color = [UIColor xcf_yellowButtonAndLabelBGColor];
//    return [UIImage xcf_imageWithColor:color];
//}
//
//+ (instancetype)xcf_buttonEHighlightedBackgroundImage {
//    UIColor *color = [[UIColor xcf_yellowButtonAndLabelBGColor] colorWithAlphaComponent:0.5];
//    return [UIImage xcf_imageWithColor:color];
//}
//
//+ (instancetype)xcf_buttonHNormalBackgroundImage {
//    UIColor *color = [UIColor xcf_blueBackgroundColor];
//    return [UIImage xcf_imageWithColor:color];
//}
//
//+ (instancetype)xcf_buttonHHighlightedBackgroundImage {
//    UIColor *color = [UIColor xcf_blueHighlightedBackgroundColor];
//    return [UIImage xcf_imageWithColor:color];
//}
//
//+ (instancetype)xcf_buttonINormalBackgroundImage {
//    UIColor *color = [UIColor xcf_grayColor];
//    return [UIImage xcf_imageWithColor:color];
//}
//
//+ (instancetype)xcf_buttonIHighlightedBackgroundImage {
//    UIColor *color = [UIColor xcf_colorWithHexString:@"#A3A399"];
//    return [UIImage xcf_imageWithColor:color];
//}
//
//+ (instancetype)xcf_buttonJNormalBackgroundImage {
//    UIColor *color = [UIColor xcf_wechatGreenColor];
//    return [UIImage xcf_imageWithColor:color];
//}
//
//+ (instancetype)xcf_buttonJHighlightedBackgroundImage {
//    UIColor *color = [[UIColor xcf_wechatGreenColor] colorWithAlphaComponent:0.5];
//    return [UIImage xcf_imageWithColor:color];
//}

@end

//#define XCFAppearanceButtonImplementation(type)          \
//@implementation XCFAppearanceButton##type                \
//                                                         \
//- (void)prepareForInterfaceBuilder                       \
//{                                                        \
//    [super prepareForInterfaceBuilder];                  \
//    [self xcf_applyStyle:XCFAppearanceButtonStyle##type];\
//}                                                        \
//                                                         \
//- (void)awakeFromNib                                     \
//{                                                        \
//    [super awakeFromNib];                                \
//    self.layer.masksToBounds = YES;                      \
//}                                                        \
//                                                         \
//- (instancetype)initWithFrame:(CGRect)frame              \
//{                                                        \
//    self = [super initWithFrame:frame];                  \
//    if(self) {                                           \
//        self.layer.masksToBounds = YES;                  \
//    }                                                    \
//    return self;                                         \
//}                                                        \
//@end

//XCFAppearanceButtonImplementation(A)
//XCFAppearanceButtonImplementation(B)
//XCFAppearanceButtonImplementation(C)
//XCFAppearanceButtonImplementation(D)
//XCFAppearanceButtonImplementation(E)
//XCFAppearanceButtonImplementation(F)
//XCFAppearanceButtonImplementation(G)
//XCFAppearanceButtonImplementation(H)
//XCFAppearanceButtonImplementation(I)
//XCFAppearanceButtonImplementation(J)

#pragma mark - compatibility


//@implementation XcfAppearanceButtonA
//@end
//@implementation XcfAppearanceButtonB
//@end
//@implementation XcfAppearanceButtonC
//@end
//@implementation XcfAppearanceButtonD
//@end
//@implementation XcfAppearanceButtonE
//@end
//@implementation XcfAppearanceButtonF
//@end
//@implementation XcfAppearanceButtonG
//@end
//@implementation XcfAppearanceButtonH
//@end
//@implementation XcfAppearanceButtonI
//@end
