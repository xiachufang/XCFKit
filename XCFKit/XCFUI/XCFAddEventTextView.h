//
//  XCFAddEventHeaderView.h
//  xcf-iphone
//
//  Created by Alex on 2016/12/12.
//  Copyright © 2016年 Xiachufang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XCFAddEventProtocol.h"

@interface XCFAddEventTextView : UITextView

@property (nonatomic, strong) NSDictionary *selectedTextAttributes;
@property (nonatomic, strong) NSDictionary *inputTextAttributes;
@property (nonatomic, strong) NSArray <id <XCFAddEventProtocol>> *events;

@property (nonatomic, copy) void (^textViewHeightChangedBlock)(CGFloat height);
@property (nonatomic, copy) void (^eventDeletedBlock)(NSInteger deleteEventIndex);
@property (nonatomic, copy) void (^searchKeyWordChangedBlock)(NSString *searchKeyWord);

@end
