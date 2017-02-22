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
        
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.transitioningDelegate = self;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    _playerView = [[XCFAVPlayerView alloc] initWithFrame:self.view.bounds];
    _playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _playerView.delegate = self;
    _playerView.fillPlayerWindow = NO;
    _playerView.volume = 1;
    [self.view addSubview:_playerView];
    
    if (_previewImage) {
        _previewImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _previewImageView.contentMode = UIViewContentModeScaleAspectFit;
        _previewImageView.image = _previewImage;
        _previewImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _previewImageView.userInteractionEnabled = NO;
        [self.view insertSubview:_previewImageView aboveSubview:_playerView];
    }
    
    // add touch action
    UITapGestureRecognizer *tap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(tapOnVideoPlayer:)];
    self.playerView.userInteractionEnabled = YES;
    [self.playerView addGestureRecognizer:tap];
    
    // prepareToPlay
    if (!_isVideoLoaded && _actualVideoPath) {
        [self.playerView prepareToPlayVideoAtPath:_actualVideoPath];
    } else if (_remoteVideoURL) {
        [self.playerView prepareToPlayVideoWithURL:_remoteVideoURL];
    }
    
    // notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pause)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pause)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(play)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.playerView play];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.playerView pause];
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
    
    if (!self.isBeingPresented && [UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        [self play];
    }
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

- (void) avPlayerViewDidReadyToPlay:(XCFAVPlayerView *)playerView
{
    [self _videoDidLoaded];
}

- (void) avPlayerView:(XCFAVPlayerView *)playerView failedToPlayWithError:(NSError *)error
{
    [self _presentError:error];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (void) beginPresentAnimation
{
    self.playerView.hidden = YES;
    self.previewImageView.hidden = YES;
}

- (void) endPresentAnimation
{
    self.playerView.hidden = NO;
    self.previewImageView.hidden = NO;
}

- (void) beginDismissAnimation
{
    self.playerView.hidden = YES;
    self.previewImageView.hidden = YES;
}

- (void) endDismissAnimation
{
    // do nothing
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    if (self.sourceController && self.sourceView && self.sourceImage) {
        XCFAVPlayerControllerAnimator *animator = [XCFAVPlayerControllerAnimator new];
        animator.avPlayerController = self;
        animator.presentingController = self.sourceController;
        
        UIImageView *animateImageView = [UIImageView new];
        animateImageView.clipsToBounds = YES;
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
        animator.presentingController = self.sourceController;
        
        UIImageView *animateImageView = [UIImageView new];
        animateImageView.clipsToBounds = YES;
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
