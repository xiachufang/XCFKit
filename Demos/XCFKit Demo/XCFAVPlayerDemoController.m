//
//  XCFAVPlayerDemoController.m
//  XCFKit Demo
//
//  Created by Li Guoyin on 2016/12/19.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import "XCFAVPlayerDemoController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>
#import <XCFKit/XCFAVPlayerView.h>

@interface XCFAVPlayerDemoController ()
<
UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
XCFAVPlayerViewDelegate
>

@property (strong, nonatomic) IBOutlet UIView *playerContainerView;
@property (strong, nonatomic) XCFAVPlayerView *playerView;

@end

@implementation XCFAVPlayerDemoController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _playerView = [[XCFAVPlayerView alloc] initWithFrame:self.playerContainerView.bounds];
    _playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _playerView.delegate = self;
    _playerView.loopCount = 0;
    [self.playerContainerView addSubview:_playerView];
}

#pragma mark - actions

- (IBAction)selectMicroVideo:(id)sender {
    UIImagePickerController *videoPicker = [UIImagePickerController new];
    videoPicker.delegate = self;
    videoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    videoPicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie,nil];
    [self presentViewController:videoPicker
                       animated:YES
                     completion:nil];
    
    [self.playerView pause];
}

- (void) didSelectVideoAtPath:(NSString *) path
{
    [self.playerView prepareToPlayVideoAtPath:path];
}

#pragma mark - XCFAVPlayerViewDelegate

- (void) avPlayerViewDidReadyToPlay:(XCFAVPlayerView *)playerView
{
    [playerView play];
}

#pragma mark - UIImagePickerControllerDelegate

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [self.playerView play];
    }];
}

- (void) imagePickerController:(UIImagePickerController *)picker
 didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    NSLog(@"%@",info);
    
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    if (CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
        NSURL *videoURL = [info objectForKey:UIImagePickerControllerReferenceURL];
        PHFetchResult *resut = [PHAsset fetchAssetsWithALAssetURLs:@[videoURL] options:nil];
        PHAsset *phAsset = resut.firstObject;
        if (phAsset) {
            
            __weak typeof(self) weak_self = self;
            [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                AVURLAsset *urlAsset = (AVURLAsset*)asset;
                NSData *data = [NSData dataWithContentsOfURL:urlAsset.URL];
                NSString *targetPath = [NSTemporaryDirectory() stringByAppendingPathComponent:urlAsset.URL.lastPathComponent];
                if ([data writeToFile:targetPath atomically:YES]) {
                    [weak_self didSelectVideoAtPath:targetPath];
                }
            }];
        }
    }
    
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
