//
//  XCFAVPlayerController.m
//  XCFKit
//
//  Created by Li Guoyin on 2016/12/19.
//  Copyright © 2016年 XiaChuFang. All rights reserved.
//

#import "XCFAVPlayerController.h"
#import "XCFAVPlayerView.h"
#import "XCFAVPlayerControllerAnimator.h"

@interface XCFAVPlayerController ()
<
XCFAVPlayerViewDelegate,
UIViewControllerTransitioningDelegate
>

@property (nonatomic, strong) NSString *actualVideoPath;
@property (nonatomic, strong) NSURL *remoteVideoURL;

@property (nonatomic, strong) XCFAVPlayerView *playerView;

@property (nonatomic, strong) UIImageView *previewImageView;

// control interface
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *playButton; // play or pause
@property (nonatomic, strong) UILabel  *currentTimeLabel;
@property (nonatomic, strong) UILabel  *durationLabel;
@property (nonatomic, strong) UISlider *progressSlider;

@end

@implementation XCFAVPlayerController
{
    BOOL _isVideoAtLocal;
    BOOL _isVideoLoaded;
    BOOL _allowPlaybackControls;
    BOOL _playbackControlsVisible;
    
    UIImage *_previewImage;
    
    struct {
        unsigned int didCancel   : 1;
        unsigned int playToEnd   : 1;
        unsigned int didDownload : 1;
    } _delegateFlag;
}

#pragma mark - life cycle

- (void) dealloc
{
    _playerView = nil;
}

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithVideoFilePath:nil
                          previewImage:nil
                 allowPlaybackControls:NO];
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    return [self initWithVideoFilePath:nil
                          previewImage:nil
                 allowPlaybackControls:NO];
}

- (instancetype) initWithVideoFilePath:(NSString *)videoPath
                          previewImage:(UIImage *)previewImage
                 allowPlaybackControls:(BOOL)allowPlaybackControls
{
    NSParameterAssert(videoPath);
    
    return [self initWithVideoURL:[NSURL fileURLWithPath:videoPath]
                     previewImage:previewImage
            allowPlaybackControls:allowPlaybackControls];
}

- (instancetype) initWithVideoURL:(NSURL *)videoURL
                     previewImage:(UIImage *)previewImage
            allowPlaybackControls:(BOOL)allowPlaybackControls
{
    NSParameterAssert(videoURL);
    
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        if (videoURL.isFileURL) {
            _isVideoAtLocal = YES;
            _actualVideoPath = videoURL.path;
        } else {
            _remoteVideoURL = [videoURL copy];
            _isVideoAtLocal = NO;
        }
        
        _allowPlaybackControls = allowPlaybackControls;
        _previewImage = previewImage;
        _sourceImageContentMode = UIViewContentModeScaleAspectFit;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    _playerView = [[XCFAVPlayerView alloc] initWithFrame:self.view.bounds];
    _playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _playerView.delegate = self;
    [self.view addSubview:_playerView];
    
    if (_previewImage) {
        _previewImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _previewImageView.contentMode = UIViewContentModeScaleAspectFit;
        _previewImageView.image = _previewImage;
        _previewImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _previewImageView.userInteractionEnabled = NO;
        [self.view insertSubview:_previewImageView aboveSubview:_playerView];
    }
    
    // presention animation
    if (self.sourceController && self.sourceView && self.sourceImage) {
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.transitioningDelegate = self;
    }
    
    // add touch action
    UITapGestureRecognizer *tap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(tapOnVideoPlayer:)];
    self.playerView.userInteractionEnabled = YES;
    [self.playerView addGestureRecognizer:tap];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!_isVideoLoaded && _actualVideoPath) {
        __weak typeof(self) weak_self = self;
        [self.playerView prepareToPlayVideoAtPath:_actualVideoPath
                                       completion:^(BOOL completion, NSError * _Nullable error) {
                                           __strong typeof(weak_self) strong_self = weak_self;
                                           if (!strong_self) return;
                                           if (completion) {
                                               [strong_self _videoDidLoaded];
                                           } else if (error) {
                                               [strong_self _presentError:error];
                                           }
                                       }];
    }
}

- (BOOL) prefersStatusBarHidden
{
    return YES;
}

#pragma mark - delegate

- (void) setDelegate:(id<XCFAVPlayerControllerDelegate>)delegate
{
    _delegate = delegate;
    
    _delegateFlag.didCancel = [delegate respondsToSelector:@selector(avPlayerControllerDidCancel:)];
    _delegateFlag.playToEnd = [delegate respondsToSelector:@selector(avPlayerControllerDidPlayToEnd:)];
    _delegateFlag.didDownload = [delegate respondsToSelector:@selector(avPlayerController:didDownloadVideoWithURL:temporaryLocalURL:)];
}

#pragma mark - layout

- (void) createControlInterface
{
    // todo
}

- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    
}

- (CGRect) videoRect
{
    return self.playerView.videoRect;
}

#pragma mark - action

- (void) _presentError:(NSError *)error
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:error.domain
                                                                             message:error.localizedDescription
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
    [alertController addAction:action];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void) _videoDidLoaded
{
    self->_isVideoLoaded = YES;
    [_previewImageView removeFromSuperview];
    _previewImageView = nil;
    
    [self play];
}

- (void) _togglePlaybackControlsVisibility
{
    // todo
}

- (void) tapOnVideoPlayer:(id)sender
{
    if (_allowPlaybackControls) {
        [self _togglePlaybackControlsVisibility];
    } else {
        [self closeDisplayAction:sender];
    }
}

- (void) closeDisplayAction:(id)sender
{
    if (_delegateFlag.didCancel) {
        [self.delegate avPlayerControllerDidCancel:self];
    }
}

#pragma mark - XCFAVPlayerViewDelegate

- (void) avPlayerViewDidPlayToEnd:(XCFAVPlayerView *)playerView
{
    if (playerView == self.playerView && _delegateFlag.playToEnd) {
        [self.delegate avPlayerControllerDidPlayToEnd:self];
    }
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    if (self.sourceController && self.sourceView && self.sourceImage) {
        XCFAVPlayerControllerAnimator *animator = [XCFAVPlayerControllerAnimator new];
        animator.avPlayerController = self;
        
        UIImageView *animateImageView = [UIImageView new];
        animateImageView.backgroundColor = [UIColor blackColor];
        animateImageView.image = self.sourceImage;
        animateImageView.contentMode = self.sourceImageContentMode;
        
        animator.animateImageView = animateImageView;
        animator.sourceFrame = [self.sourceController.view convertRect:self.sourceView.bounds
                                                              fromView:self.sourceView];
        animator.isPresenting = YES;
        return animator;
    }
    
    return nil;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    if (self.sourceController && self.sourceView && self.sourceImage) {
        XCFAVPlayerControllerAnimator *animator = [XCFAVPlayerControllerAnimator new];
        animator.avPlayerController = self;
        
        UIImageView *animateImageView = [UIImageView new];
        animateImageView.backgroundColor = [UIColor blackColor];
        animateImageView.image = self.sourceImage;
        animateImageView.contentMode = self.sourceImageContentMode;
        
        animator.animateImageView = animateImageView;
        animator.sourceFrame = [self videoRect];
        animator.destinationFrame = [self.sourceController.view convertRect:self.sourceView.bounds
                                                              fromView:self.sourceView];
        animator.isPresenting = NO;
        return animator;
    }
    
    return nil;
}

#pragma mark - XCFVideoPlayerControlProtocol

- (void) play
{
    [self.playerView play];
}

- (void) pause
{
    [self.playerView pause];
}

- (void) stop
{
    [self.playerView stop];
}

- (BOOL) isPlaying
{
    return [self.playerView isPlaying];
}

- (CGFloat) progress
{
    return [self.playerView progress];
}

@end
