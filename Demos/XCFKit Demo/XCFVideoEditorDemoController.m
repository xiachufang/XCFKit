//
//  XCFVideoEditorDemoController.m
//  XCFKit Demo
//
//  Created by Li Guoyin on 2017/1/13.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import "XCFVideoEditorDemoController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>
#import <XCFKit/XCFVideoEditorController.h>
#import <XCFKit/XCFAVPlayerController.h>

@interface XCFVideoEditorDemoController ()
<
UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
XCFVideoEditorControllerDelegate,
XCFAVPlayerControllerDelegate
>

@property (strong, nonatomic) IBOutlet UISegmentedControl *aspectSegmentControl;

@end

@implementation XCFVideoEditorDemoController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)selectVideo:(id)sender {
    UIImagePickerController *videoPicker = [UIImagePickerController new];
    videoPicker.delegate = self;
    videoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    videoPicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie,nil];
    videoPicker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    [self presentViewController:videoPicker
                       animated:YES
                     completion:nil];
}

- (void) didSelectVideo:(AVAsset *)asset
{
    XCFVideoEditorController *editor = [[XCFVideoEditorController alloc] initWithVideoAsset:asset];
    editor.delegate = self;
    XCFVideoEditorVideoQualityType aspect = XCFVideoEditorVideoQualityType1x1;
    if (self.aspectSegmentControl.selectedSegmentIndex == 1) {
        aspect = XCFVideoEditorVideoQualityType4x3;
    } else if (self.aspectSegmentControl.selectedSegmentIndex == 2) {
        aspect = XCFVideoEditorVideoQualityType5x4;
    }
    editor.videoQuality = XCFVideoEditorVideoQualityTypeMedium | aspect;
    [self.navigationController pushViewController:editor animated:YES];
}

#pragma mark - UIImagePickerControllerDelegate

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void) imagePickerController:(UIImagePickerController *)picker
 didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    if (CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
        NSURL *videoURL = [info objectForKey:UIImagePickerControllerReferenceURL];
        PHFetchResult *resut = [PHAsset fetchAssetsWithALAssetURLs:@[videoURL] options:nil];
        PHAsset *phAsset = resut.firstObject;
        if (phAsset) {
            [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self didSelectVideo:asset];
                });
            }];
        }
    }
    
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - XCFVideoEditorControllerDelegate

- (void) videoEditorController:(XCFVideoEditorController *)editor didFailWithError:(NSError *)error
{
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"Error"
                                        message:error.localizedDescription
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
    [alert addAction:action];
    [editor presentViewController:alert animated:YES completion:nil];
}

- (void) videoEditorController:(XCFVideoEditorController *)editor didSaveEditedVideoToPath:(NSString *)editedVideoPath videoInfo:(NSDictionary *)videoInfo
{
    NSData *videoData = [NSData dataWithContentsOfFile:editedVideoPath];
    NSString *byteLength = [NSByteCountFormatter stringFromByteCount:videoData.length
                                                          countStyle:NSByteCountFormatterCountStyleFile];
    
    NSNumber *width = [videoInfo valueForKey:XCFVideoEditorVideoInfoWidth];
    NSNumber *height = [videoInfo valueForKey:XCFVideoEditorVideoInfoHeight];
    NSNumber *duration = [videoInfo valueForKey:XCFVideoEditorVideoInfoDuration];
    
    NSString *message = [NSString stringWithFormat:@"size : {%@,%@}\nduration : %@s\nstorage : %@",width,height,duration,byteLength];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"导出成功"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"好的"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
    UIAlertAction *play = [UIAlertAction actionWithTitle:@"播放" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
         XCFAVPlayerController *player = [[XCFAVPlayerController alloc] initWithVideoFilePath:editedVideoPath
                                                                                 previewImage:nil
                                                                        allowPlaybackControls:NO];
         player.delegate = self;
         [editor presentViewController:player animated:YES completion:nil];
     }];
    
    [alert addAction:cancel];
    [alert addAction:play];
    
    [editor presentViewController:alert animated:YES completion:nil];
}

#pragma mark - XCFAVPlayerControllerDelegate

- (void) avPlayerControllerDidCancel:(XCFAVPlayerController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
