//
//  XCFVideoRangeSliderDemoController.m
//  XCFKit Demo
//
//  Created by Li Guoyin on 2017/1/11.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import "XCFVideoRangeSliderDemoController.h"
#import <XCFKit/XCFVideoRangeSlider.h>

#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>

@interface XCFVideoRangeSliderDemoController ()
<
UINavigationControllerDelegate,
UIImagePickerControllerDelegate
>

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *videoClipLeadingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *videoClipWidthConstraint;

@property (strong, nonatomic) IBOutlet UILabel *rangeIndicatorLabel;
@property (strong, nonatomic) IBOutlet UIView *rangeSliderContainerView;

@property (nonatomic, strong) XCFVideoRangeSlider *slider;
@property (nonatomic, assign) XCFVideoRange currentRange;

@end

@implementation XCFVideoRangeSliderDemoController

- (void) dealloc
{
    NSLog(@"dealloc : %@",self.class);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _currentRange = (XCFVideoRange){0,0};
    
    _slider = [[XCFVideoRangeSlider alloc] initWithFrame:self.rangeSliderContainerView.bounds];
    _slider.maximumTrimLength = 6;
    _slider.tintColor = [UIColor orangeColor];
    _slider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.rangeSliderContainerView addSubview:_slider];
    
    [_slider addTarget:self
                action:@selector(videoRangeChanged:)
      forControlEvents:UIControlEventValueChanged];
    
    [self updateVideoClipLayout];
}

- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateVideoClipLayout];
}

#pragma mark - layout

- (void) updateVideoClipLayout
{
    NSTimeInterval start = self.currentRange.location;
    NSTimeInterval end   = start + self.currentRange.length;
    
    self.rangeIndicatorLabel.text = [NSString stringWithFormat:@"%.1lf - %.1lf",start,end];
    
    CGFloat startRatio = 0;
    CGFloat endRatio   = 0;
    
    NSTimeInterval videoLength = self.slider.videoLength;
    if (videoLength > 0) {
        startRatio = start / videoLength;
        endRatio   = end   / videoLength;
    }
    
    CGFloat width = self.view.bounds.size.width;
    self.videoClipLeadingConstraint.constant = startRatio * width;
    self.videoClipWidthConstraint.constant = (endRatio - startRatio) * width;
}

#pragma mark - action

- (void) videoRangeChanged:(XCFVideoRangeSlider *)slider
{
    self.currentRange = slider.currentRange;
    [self updateVideoClipLayout];
}

- (void) didSelectVideo:(AVAsset *)asset
{
    [self.slider loadVideoFramesWithVideoAsset:asset];
    self.navigationItem.rightBarButtonItem = nil;
}

- (IBAction)pickVideo:(UIBarButtonItem *)sender
{
    UIImagePickerController *videoPicker = [UIImagePickerController new];
    videoPicker.delegate = self;
    videoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    videoPicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie,nil];
    videoPicker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    [self presentViewController:videoPicker
                       animated:YES
                     completion:nil];
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

@end
