//
//  XCFMicroVideoPlayerDemoController.m
//  XCFKit Demo
//
//  Created by Li Guoyin on 2016/12/16.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import "XCFMicroVideoPlayerDemoController.h"
#import <XCFKit/XCFMicroVideoPlayerView.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>
#import <XCFKit/XCFAVPlayerController.h>

@interface XCFMicroVideoPlayerDemoController ()
<
UIImagePickerControllerDelegate,
UINavigationControllerDelegate,
XCFAVPlayerControllerDelegate
>

@property (nonatomic, strong) IBOutlet UIView *videoPlayerContainerView;

@property (nonatomic, strong) XCFMicroVideoPlayerView *playerView;

@end

@implementation XCFMicroVideoPlayerDemoController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *previewImagePath = [[NSBundle mainBundle] pathForResource:@"microVideoPlayerPreviewImage"
                                                                 ofType:@"jpg"];
    UIImage *previewImage = [[UIImage alloc] initWithContentsOfFile:previewImagePath];
    _playerView = [[XCFMicroVideoPlayerView alloc] initWithFrame:self.videoPlayerContainerView.bounds
                                                       videoPath:nil
                                                    previewImage:previewImage];
    _playerView.fillWindow = YES;
    _playerView.loopCount = 0;
    _playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.videoPlayerContainerView addSubview:_playerView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(tapOnPlayerView:)];
    [_playerView addGestureRecognizer:tap];
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
    if (path) {
        XCFMicroVideoDecoder *decoder = [[XCFMicroVideoDecoder alloc] initWithVideoFilePath:path];
        [self.playerView switchToVideoDecoder:decoder];
        [self.playerView play];
    }
}

- (void) tapOnPlayerView:(id)sender
{
    if (self.playerView.progress >= 0) {
        [self.playerView pause];
        
        UIImage *previewImage = [self.playerView screenshot];
        XCFAVPlayerController *controller =
        [[XCFAVPlayerController alloc] initWithVideoFilePath:self.playerView.videoPath
                                                previewImage:previewImage
                                       allowPlaybackControls:NO];
        controller.delegate = self;
        controller.sourceController = self;
        controller.sourceView = self.playerView;
        controller.sourceImage = previewImage;
        [self presentViewController:controller
                           animated:YES
                         completion:nil];
    }
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
            PHVideoRequestOptions *options=[[PHVideoRequestOptions alloc]init];
            options.version=PHVideoRequestOptionsVersionOriginal;
            [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                AVURLAsset *urlAsset = (AVURLAsset*)asset;
                NSData *data = [NSData dataWithContentsOfURL:urlAsset.URL];
                NSString *targetPath = [NSTemporaryDirectory() stringByAppendingPathComponent:urlAsset.URL.lastPathComponent];
                if ([data writeToFile:targetPath atomically:YES]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weak_self didSelectVideoAtPath:targetPath];
                    });   
                }
            }];
        }
    }
    
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - XCFAVPlayerControllerDelegate

- (void) avPlayerControllerDidCancel:(XCFAVPlayerController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:^{
        if (self.playerView.progress < 1) {
            [self.playerView play];
        }
    }];
}

@end
