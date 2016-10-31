//
//  XCFAppearanceButton.h
//  XCFKit
//
//  Created by Li Guoyin on 2016/10/28.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    XCFAppearanceButtonStyleA,
    XCFAppearanceButtonStyleB,
    XCFAppearanceButtonStyleC,
    XCFAppearanceButtonStyleD,
    XCFAppearanceButtonStyleE,
    XCFAppearanceButtonStyleF,
    XCFAppearanceButtonStyleG,
    XCFAppearanceButtonStyleH,
    XCFAppearanceButtonStyleI
} XCFAppearanceButtonStyle;

@interface UIButton (XCFAppearance)

- (void) xcf_applyStyle:(XCFAppearanceButtonStyle)style;

@end

@interface UIImage (XCFAppearanceButton)

+ (instancetype)xcf_mainButtonNormalBackgroundImage;
+ (instancetype)xcf_mainButtonSelectedBackgroundImage;
+ (instancetype)xcf_buttonBHighlightedBackgroundImage;
+ (instancetype)xcf_buttonENormalBackgroundImage;
+ (instancetype)xcf_buttonEHighlightedBackgroundImage;
+ (instancetype)xcf_buttonHNormalBackgroundImage;
+ (instancetype)xcf_buttonHHighlightedBackgroundImage;
+ (instancetype)xcf_buttonINormalBackgroundImage;
+ (instancetype)xcf_buttonIHighlightedBackgroundImage;

@end


IB_DESIGNABLE
@interface XCFAppearanceButtonA : UIButton
@end

IB_DESIGNABLE
@interface XCFAppearanceButtonB : UIButton
@end

IB_DESIGNABLE
@interface XCFAppearanceButtonC : UIButton
@end

IB_DESIGNABLE
@interface XCFAppearanceButtonD : UIButton
@end

IB_DESIGNABLE
@interface XCFAppearanceButtonE : UIButton
@end

IB_DESIGNABLE
@interface XCFAppearanceButtonF : XCFAppearanceButtonD
@end

IB_DESIGNABLE
@interface XCFAppearanceButtonG : UIButton
@end

IB_DESIGNABLE
@interface XCFAppearanceButtonH : UIButton
@end

IB_DESIGNABLE
@interface XCFAppearanceButtonI : UIButton
@end

#pragma mark - compatibility

@compatibility_alias XcfAppearanceButtonA XCFAppearanceButtonA;
@compatibility_alias XcfAppearanceButtonB XCFAppearanceButtonB;
@compatibility_alias XcfAppearanceButtonC XCFAppearanceButtonC;
@compatibility_alias XcfAppearanceButtonD XCFAppearanceButtonD;
@compatibility_alias XcfAppearanceButtonE XCFAppearanceButtonE;
@compatibility_alias XcfAppearanceButtonF XCFAppearanceButtonF;
@compatibility_alias XcfAppearanceButtonG XCFAppearanceButtonG;
@compatibility_alias XcfAppearanceButtonH XCFAppearanceButtonH;
@compatibility_alias XcfAppearanceButtonI XCFAppearanceButtonI;


