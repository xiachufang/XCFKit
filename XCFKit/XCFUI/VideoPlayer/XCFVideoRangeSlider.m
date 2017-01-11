//
//  XCFVideoRangerSlider.m
//  XCFKit
//
//  Created by Li Guoyin on 2017/1/4.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import "XCFVideoRangeSlider.h"
#import <AVFoundation/AVFoundation.h>

@interface _XCFVideoRangerSliderCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation _XCFVideoRangerSliderCell

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _imageView.userInteractionEnabled = NO;
        [self.contentView addSubview:_imageView];
    }
    
    return self;
}

@end

static const CGFloat XCFVideoRangeSliderFrameWidth = 30.0f;

@interface XCFVideoRangeSlider ()
<
UICollectionViewDataSource,
UICollectionViewDelegate,
UIGestureRecognizerDelegate
>

@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, strong) AVAssetImageGenerator *imageGenerator;

@property (nonatomic, strong) UICollectionView *frameCollectionView;
//@property (nonatomic, assign) NSTimeInterval frameInterval;
@property (nonatomic, strong) NSMutableArray *cachedFrames;

@property (nonatomic, strong) UIView *slider;

@end

@implementation XCFVideoRangeSlider
{
    UIView *_outsideOverlayView;
    UIView *_insideBoundLeftView;
    UIView *_insideBoundTopView;
    UIView *_insideBoundBottomView;
    
    CGPoint _trackInitPoint;
    XCFVideoRange _trackInitRange;
}

- (void) dealloc
{
    [_imageGenerator cancelAllCGImageGeneration];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self commonInit];
}

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (void) commonInit
{
    _minimumTrimLength = 3;
    _maximumTrimLength = 15;
    _currentRange = XCFVideoRangeEmpty;
    
    self.backgroundColor = [UIColor blackColor];
    
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    layout.sectionInset = UIEdgeInsetsZero;
    _frameCollectionView = [[UICollectionView alloc] initWithFrame:self.bounds
                                              collectionViewLayout:layout];
    _frameCollectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _frameCollectionView.delegate         = self;
    _frameCollectionView.dataSource       = self;
    [self addSubview:_frameCollectionView];
    
    [_frameCollectionView registerClass:[_XCFVideoRangerSliderCell class]
             forCellWithReuseIdentifier:@"frameCell"];
    
    _outsideOverlayView = [UIView new];
    _outsideOverlayView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.4];
    [self addSubview:_outsideOverlayView];
    
    // inside bounds
    {
        _insideBoundLeftView = [UIView new];
        _insideBoundLeftView.backgroundColor = self.tintColor;
        _insideBoundLeftView.userInteractionEnabled = NO;
        [self addSubview:_insideBoundLeftView];
    }
    {
        _insideBoundTopView = [UIView new];
        _insideBoundTopView.backgroundColor = self.tintColor;
        _insideBoundTopView.userInteractionEnabled = NO;
        [self addSubview:_insideBoundTopView];
    }
    {
        _insideBoundBottomView = [UIView new];
        _insideBoundBottomView.backgroundColor = self.tintColor;
        _insideBoundBottomView.userInteractionEnabled = NO;
        [self addSubview:_insideBoundBottomView];
    }
    
    // slider
    _slider = [UIView new];
    _slider.tintColor = self.tintColor;
    _slider.userInteractionEnabled = NO;
    [self addSubview:_slider];
}

#pragma mark - configure

- (void) setCurrentRange:(XCFVideoRange)currentRange
{
    // todo
}

- (void) tintColorDidChange
{
    [super tintColorDidChange];
    
    self.slider.tintColor                  = self.tintColor;
    _insideBoundTopView.backgroundColor    = self.tintColor;
    _insideBoundLeftView.backgroundColor   = self.tintColor;
    _insideBoundBottomView.backgroundColor = self.tintColor;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat height = CGRectGetHeight(self.bounds);
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*)self.frameCollectionView.collectionViewLayout;
    CGSize itemSize = CGSizeMake(XCFVideoRangeSliderFrameWidth, height);
    if (!CGSizeEqualToSize(itemSize, layout.itemSize)) {
        layout.itemSize = itemSize;
        [self.frameCollectionView reloadData];
    }
    
    [self updateOverlayViewLayout];
}

- (void) updateOverlayViewLayout
{
    CGRect bounds = self.bounds;
    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = CGRectGetHeight(bounds);
    
    NSParameterAssert(self.currentRange.length <= [self _actualMaximumTrimLength]);
    
    CGFloat progress = MIN(1,self.currentRange.length / self.maximumTrimLength) * width;
    
    CGRect layoutFrame = bounds;
    CGRect overlayFrame;
    CGRectDivide(layoutFrame, &layoutFrame, &overlayFrame, progress, CGRectMinXEdge);
    _outsideOverlayView.frame = overlayFrame;
    
    CGFloat insideBoundWidth = 2;
    CGRect boundFrame;
    CGRectDivide(layoutFrame, &boundFrame, &layoutFrame, insideBoundWidth, CGRectMinXEdge);
    _insideBoundLeftView.frame = boundFrame;
    
    CGRectDivide(layoutFrame, &boundFrame, &layoutFrame, insideBoundWidth, CGRectMinYEdge);
    _insideBoundTopView.frame = boundFrame;
    
    CGRectDivide(layoutFrame, &boundFrame, &layoutFrame, insideBoundWidth, CGRectMaxYEdge);
    _insideBoundBottomView.frame = boundFrame;
    
    CGFloat sliderWidth = 15;
    self.slider.frame = CGRectMake(progress - sliderWidth, -5, sliderWidth, height + 10);
    
    CGFloat frameOffset = self.frameCollectionView.contentOffset.x;
    if (self.frameCollectionView.contentSize.width + frameOffset < progress) {
        CGFloat adjustOffset = progress - self.frameCollectionView.contentSize.width;
        self.frameCollectionView.contentOffset = CGPointMake(adjustOffset, 0);
    }
    UIEdgeInsets insets = self.frameCollectionView.contentInset;
    insets.right = width - progress;
    self.frameCollectionView.contentInset = insets;
}

#pragma mark - load asset

- (void) loadVideoFramesWithVideoAsset:(AVAsset *)asset
{
    NSParameterAssert(asset && asset.providesPreciseDurationAndTiming);
    
    self.asset = asset;
    _videoLength = CMTimeGetSeconds(asset.duration);
    NSLog(@"video length is %.2lf",_videoLength);
    
    _imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.asset];
    _imageGenerator.appliesPreferredTrackTransform = YES;
    _imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    _imageGenerator.requestedTimeToleranceAfter  = kCMTimeZero;
    
    _cachedFrames = [NSMutableArray arrayWithCapacity:MIN(15, _videoLength)];
    
    NSString *loadKey = @"tracks";
    NSError *error = nil;
    AVKeyValueStatus loadStatus = [self.asset statusOfValueForKey:loadKey
                                                             error:&error];
    if (loadStatus == AVKeyValueStatusLoaded) {
        AVAssetTrack *track = [self.asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        if (track) {
            CGSize trackSize = track.naturalSize;
            if (trackSize.width > 0) {
                CGFloat thumbnailHeight = trackSize.height / trackSize.width * XCFVideoRangeSliderFrameWidth;
                _imageGenerator.maximumSize = CGSizeMake(XCFVideoRangeSliderFrameWidth, thumbnailHeight);
            }
        }
    }
}

- (UIImage *) generateThumbnailImageAtIndex:(NSInteger)index
{
    NSLog(@"get image at index : %zd",index);
    
    if (index < self.cachedFrames.count) {
        return self.cachedFrames[index];
    }
    
    CGFloat width = self.bounds.size.width;
    NSTimeInterval targetSecond = (index + 0.5) * XCFVideoRangeSliderFrameWidth / width * self.maximumTrimLength;
    if (targetSecond > self.videoLength) {
        targetSecond = self.videoLength;
    }
    
    CMTime targetTime = CMTimeMakeWithSeconds(targetSecond, 600);
    CMTime actualTime; NSError *error;
    CGImageRef imageRef = [self.imageGenerator copyCGImageAtTime:targetTime
                                                       actualTime:&actualTime
                                                            error:&error];
    if (imageRef) {
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        if (index == self.cachedFrames.count) {
            [self.cachedFrames insertObject:image atIndex:index];
            NSLog(@"insert new image at index : %zd",index);
        }
        
        return image;
    }
    
    return nil;
}

- (NSTimeInterval) _actualMaximumTrimLength
{
    return MIN(self.videoLength, self.maximumTrimLength);
}

#pragma mark - collection delegate

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return ceil(self.videoLength / self.maximumTrimLength * collectionView.bounds.size.width / XCFVideoRangeSliderFrameWidth);
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    _XCFVideoRangerSliderCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"frameCell"
                                                                                forIndexPath:indexPath];
    cell.imageView.image = [self generateThumbnailImageAtIndex:indexPath.item];
    return cell;
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.frameCollectionView) {
        CGFloat offset = -self.frameCollectionView.contentOffset.x;
        NSTimeInterval time = offset / scrollView.bounds.size.width * self.maximumTrimLength;
        time = MAX(MIN(time, self.videoLength - self.currentRange.length),0);
        if (time != self.currentRange.location) {
            XCFVideoRange newRange = self.currentRange;
            newRange.location = time;
            _currentRange = newRange;
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
    }
}

#pragma mark - touch event

- (void) sendActionsForControlEvents:(UIControlEvents)controlEvents
{
    if (controlEvents & UIControlEventValueChanged) {
        [super sendActionsForControlEvents:controlEvents];
    }
}

- (UIView *) hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGRect sliderTouchRect = CGRectInset(self.slider.frame, -20, 0);
    if (CGRectContainsPoint(sliderTouchRect, point)) {
        return self.slider;
    } else if (CGRectContainsPoint(self.frameCollectionView.frame, point)) {
        return self.frameCollectionView;
    } else {
        return nil;
    }
}

- (BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint point = [touch locationInView:self];
    _trackInitPoint = point;
    _trackInitRange = self.currentRange;
    UIView *hit = [self hitTest:point withEvent:event];
    return hit && hit == self.slider;
}

- (BOOL) continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint point = [touch locationInView:self];
    CGFloat distance = point.x - _trackInitPoint.x;
    NSTimeInterval interval = distance / self.bounds.size.width * self.maximumTrimLength;
    NSTimeInterval newLength = self.currentRange.length + interval;
    newLength = MIN(MAX(newLength, self.minimumTrimLength),[self _actualMaximumTrimLength]);
    
    if (newLength != self.currentRange.length) {
        XCFVideoRange newRange = self.currentRange;
        newRange.length = newLength;
        _currentRange = newRange;
        [self updateOverlayViewLayout];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    
    return YES;
}

@end
