//
//  XCFKitCompat.h
//  XCFKit
//
//  Created by Li Guoyin on 2016/10/28.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <TargetConditionals.h>

// Apple's defines from TargetConditionals.h are a bit weird.
// Seems like TARGET_OS_MAC is always defined (on all platforms).
// To determine if we are running on OSX, we can only relly on TARGET_OS_IPHONE=0 and all the other platforms
#if !TARGET_OS_IPHONE && !TARGET_OS_IOS && !TARGET_OS_TV && !TARGET_OS_WATCH
#define XCF_MAC 1
#else
#define XCF_MAC 0
#endif

// iOS and tvOS are very similar, UIKit exists on both platforms
// Note: watchOS also has UIKit, but it's very limited
#if TARGET_OS_IOS || TARGET_OS_TV
#define XCF_UIKIT 1
#else
#define XCF_UIKIT 0
#endif

#if TARGET_OS_IOS
#define XCF_IOS 1
#else
#define XCF_IOS 0
#endif

#if TARGET_OS_TV
#define XCF_TV 1
#else
#define XCF_TV 0
#endif

#if TARGET_OS_WATCH
#define XCF_WATCH 1
#else
#define XCF_WATCH 0
#endif


#if XCF_MAC
#import <AppKit/AppKit.h>
#ifndef UIImage
#define UIImage NSImage
#endif
#ifndef UIImageView
#define UIImageView NSImageView
#endif
#ifndef UIView
#define UIView NSView
#endif
#else

#if XCF_UIKIT
#import <UIKit/UIKit.h>
#endif
#if XCF_WATCH
#import <WatchKit/WatchKit.h>
#endif
#endif

extern NSString *const XCFKitErrorDomain;
