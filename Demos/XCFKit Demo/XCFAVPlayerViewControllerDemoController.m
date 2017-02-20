//
//  XCFAVPlayerViewControllerDemoController.m
//  XCFKit Demo
//
//  Created by Li Guoyin on 2017/2/20.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import "XCFAVPlayerViewControllerDemoController.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface XCFAVPlayerViewControllerDemoController ()

@end

@implementation XCFAVPlayerViewControllerDemoController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction) playVideo:(id)sender
{
    NSString *videoURLString = @"http://i3.chuimg.com/3c7251a29b5c11e6ac0302e9fe59cadf_0w_0h.mp4";
    NSURL *videoURL = [NSURL URLWithString:videoURLString];
    AVPlayer *player = [AVPlayer playerWithURL:videoURL];
    AVPlayerViewController *playerController = [AVPlayerViewController new];
    playerController.player = player;
    [self presentViewController:playerController animated:YES completion:^{
        [player play];
    }];
}

@end
