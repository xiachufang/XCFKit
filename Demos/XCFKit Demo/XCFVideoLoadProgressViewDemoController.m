//
//  XCFVideoLoadProgressViewDemoController.m
//  XCFKit Demo
//
//  Created by Li Guoyin on 2017/1/18.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import "XCFVideoLoadProgressViewDemoController.h"
#import <XCFKit/XCFVideoLoadProgressView.h>

@interface XCFVideoLoadProgressViewDemoController ()

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) XCFVideoLoadProgressView *progressView;

@end

@implementation XCFVideoLoadProgressViewDemoController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect progressViewFrame = CGRectMake(0, 0, 40, 40);
    self.progressView = [[XCFVideoLoadProgressView alloc] initWithFrame:progressViewFrame];
    [self.view addSubview:self.progressView];
}

- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.progressView.center = self.imageView.center;
}

- (IBAction)progressChanged:(UISlider *)sender {
    CGFloat progress = sender.value / sender.maximumValue;
    if (progress == 0) {
        self.progressView.status = XCFVideoLoadStatusPlay;
    } else if (progress < 0.5) {
        self.progressView.status = XCFVideoLoadStatusLoading;
    } else {
        self.progressView.status = XCFVideoLoadStatusProgress;
    }
    
    self.progressView.progress = progress - 0.5;
}

@end
