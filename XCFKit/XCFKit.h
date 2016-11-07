//
//  XCFKit.h
//  XCFKit
//
//  Created by Li Guoyin on 2016/10/28.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import <XCFKit/XCFKitCompat.h>

#if XCF_UIKIT
#import <UIKit/UIKit.h>
#endif

//! Project version number for XCFKit.
FOUNDATION_EXPORT double XCFKitVersionNumber;

//! Project version string for XCFKit.
FOUNDATION_EXPORT const unsigned char XCFKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <XCFKit/PublicHeader.h>

// UI
#if XCF_UIKIT

#import <XCFKit/XCFAppearanceButton.h>
#import <XCFKit/UIFont+XCFAppearance.h>

#import <XCFKit/UIColor+Hex.h>
#import <XCFKit/UIColor+XCFAppearance.h>

#import <XCFKit/UIImage+PureColor.h>
#import <XCFKit/UIView+XCFAppearance.h>

#endif

#if XCF_WATCH

#import <XCFKit/UIColor+Hex.h>
#import <XCFKit/UIColor+XCFAppearance.h>

#endif