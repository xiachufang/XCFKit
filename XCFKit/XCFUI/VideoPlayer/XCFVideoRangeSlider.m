//
//  XCFVideoRangerSlider.m
//  XCFKit
//
//  Created by Li Guoyin on 2017/1/4.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import "XCFVideoRangeSlider.h"
#import <AVFoundation/AVFoundation.h>

#import "UIColor+XCFAppearance.h"

#define ADJUST_FRAME_SIZE_BY_TRACK 0
#define ASYNC_GENERATE_IMAGE 1

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
        _imageView.userInteractionEnabled = NO;
        [self.contentView addSubview:_imageView];
    }
    
    return self;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    // 为了弥补两个 cell 之间可能的黑线
    _imageView.frame = CGRectInset(self.contentView.bounds, -1, 0);
}

- (void) prepareForReuse
{
    [super prepareForReuse];
    
    self.imageView.image = nil;
}

@end

@interface _XCFVideoRangerSliderHandler : UIView

@property (nonatomic, strong) UIView *indicator;

@end

@implementation _XCFVideoRangerSliderHandler

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        _indicator = [UIView new];
        _indicator.backgroundColor = self.tintColor;
        [self addSubview:_indicator];
        
        self.layer.masksToBounds = YES;
    }
    
    return self;
}

- (void) tintColorDidChange
{
    _indicator.backgroundColor = self.tintColor;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    self.indicator.center = CGPointMake(width / 2, height / 2);
    self.indicator.bounds = CGRectMake(0, 0, width / 3, height / 4);
    self.indicator.layer.cornerRadius = width / 6;
    self.indicator.layer.masksToBounds = YES;
}

@end

typedef void (^XCFVideoRangeSliderThumbnailBlock)(NSInteger,UIImage*);

static const CGFloat XCFVideoRangeSliderFrameMaxWidth = 40.0f;

@interface XCFVideoRangeSlider ()
<
UICollectionViewDataSource,
UICollectionViewDelegate,
UIGestureRecognizerDelegate
>

@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, strong) AVAssetImageGenerator *imageGenerator;

@property (nonatomic, strong) UICollectionView *frameCollectionView;
@property (nonatomic, strong) NSMutableDictionary<NSNumber*,UIImage*> *cachedFrames;

@property (nonatomic, strong) _XCFVideoRangerSliderHandler *slider;
@property (nonatomic, strong) NSMutableDictionary<NSNumber*,id> *runningTasks;

@end

@implementation XCFVideoRangeSlider
{
    UIView *_outsideOverlayView;
    UIView *_insideBoundLeftView;
    UIView *_insideBoundTopView;
    UIView *_insideBoundBottomView;
    
    CGPoint _trackInitPoint;
    XCFVideoRange _trackInitRange;
    
    CGFloat _videoRangeSliderFrameWidth;
}

- (void) dealloc
{
    [_imageGenerator cancelAllCGImageGeneration];
    _cachedFrames = nil;
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
    _frameCollectionView.showsHorizontalScrollIndicator = NO;
    _frameCollectionView.decelerationRate = UIScrollViewDecelerationRateFast;
    [self addSubview:_frameCollectionView];
    
    [_frameCollectionView registerClass:[_XCFVideoRangerSliderCell class]
             forCellWithReuseIdentifier:@"frameCell"];
    
    _outsideOverlayView = [UIView new];
    _outsideOverlayView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
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
    _slider = [_XCFVideoRangerSliderHandler new];
    _slider.tintColor = [UIColor whiteColor];
    _slider.backgroundColor = [UIColor xcf_linkColor];
    _slider.userInteractionEnabled = NO;
    [self addSubview:_slider];
    
    _slider.hidden = YES;
}

#pragma mark - configure

- (void) setCurrentRange:(XCFVideoRange)currentRange
{
    // todo
}

- (void) tintColorDidChange
{
    [super tintColorDidChange];
    
    _insideBoundTopView.backgroundColor    = self.tintColor;
    _insideBoundLeftView.backgroundColor   = self.tintColor;
    _insideBoundBottomView.backgroundColor = self.tintColor;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat height = CGRectGetHeight(self.bounds);
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*)self.frameCollectionView.collectionViewLayout;
    CGSize itemSize = CGSizeMake(_videoRangeSliderFrameWidth, height);
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
    
    CGFloat sliderWidth = 8;
    self.slider.layer.cornerRadius = 2;
    self.slider.layer.masksToBounds = YES;
    self.slider.frame = CGRectMake(progress - sliderWidth + 1, -2, sliderWidth, height + 4);
    
    CGFloat frameOffset = self.frameCollectionView.contentOffset.x;
    CGFloat contentWidth = self.frameCollectionView.contentSize.width;
    if (contentWidth == 0) {
        contentWidth = width / self.maximumTrimLength * self.videoLength;
    }
    
    if (contentWidth - frameOffset < progress) {
        CGFloat adjustOffset = - progress + contentWidth;
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
//    NSLog(@"video length is %.2lf",_videoLength);
    
    CGFloat contentWidth = self.videoLength / self.maximumTrimLength * self.frameCollectionView.bounds.size.width;
    CGFloat numberOfFrames = contentWidth / XCFVideoRangeSliderFrameMaxWidth;
    numberOfFrames = ceil(numberOfFrames);
//    NSLog(@"preferrd frames : %lf",numberOfFrames);
    _videoRangeSliderFrameWidth = contentWidth / numberOfFrames;
    
    _imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.asset];
    _imageGenerator.appliesPreferredTrackTransform = YES;
    if (_videoLength <= 20) {
    _imageGenerator.requestedTimeToleranceBefore = CMTimeMake(10, 30);
    _imageGenerator.requestedTimeToleranceAfter  = CMTimeMake(10, 30);
    }
    
    NSUInteger cacheCapacity = MIN(15, _videoLength);
    _cachedFrames = [NSMutableDictionary dictionaryWithCapacity:cacheCapacity];
    _runningTasks = [NSMutableDictionary dictionaryWithCapacity:cacheCapacity];
    
#if ADJUST_FRAME_SIZE_BY_TRACK
    NSString *loadKey = @"tracks";
    __weak typeof(self) weak_self = self;
    [self.asset loadValuesAsynchronouslyForKeys:@[loadKey] completionHandler:^{
        __strong typeof(weak_self) strong_self = weak_self;
        
        NSError *error = nil;
        AVKeyValueStatus status = [strong_self.asset statusOfValueForKey:loadKey
                                                                   error:&error];
        if (status == AVKeyValueStatusLoaded) {
            AVAssetTrack *track = [strong_self.asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
            if (track) {
                CGSize trackSize = track.naturalSize;
                CGFloat heightRatio = trackSize.height / trackSize.width;
                if (!CGAffineTransformIsIdentity(track.preferredTransform)) {
                    heightRatio = trackSize.width / trackSize.height;
                }
                if (trackSize.width > 0) {
                    CGFloat thumbnailHeight = ceil(heightRatio * _videoRangeSliderFrameWidth);
                    CGFloat scale = [UIScreen mainScreen].scale;
                    strong_self.imageGenerator.maximumSize =
                    CGSizeMake(ceil(_videoRangeSliderFrameWidth * scale), thumbnailHeight * scale);
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
           [strong_self didVideoAssetLoaded]; 
        });
    }];
#else
    self.imageGenerator.maximumSize = CGSizeMake(200, 200);
    [self didVideoAssetLoaded];
#endif
    
}

- (void) didVideoAssetLoaded
{
    XCFVideoRange newRange;
    newRange.location = 0;
    newRange.length = [self _actualMaximumTrimLength];
    _currentRange = newRange;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    [self updateOverlayViewLayout];
    [self.frameCollectionView reloadData];
    
    self.slider.hidden = NO;
}

- (UIImage *) generateThumbnailImageAtIndex:(NSInteger)index
{
    UIImage *cachedImage = self.cachedFrames[@(index)];
    if (cachedImage) return cachedImage;
    
    CGFloat width = self.bounds.size.width;
    NSTimeInterval targetSecond = (index + 0.5) * _videoRangeSliderFrameWidth / width * self.maximumTrimLength;
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
        CGImageRelease(imageRef);
        if (image) {
            self.cachedFrames[@(index)] = image;
        }
        
        return image;
    }
    
    return nil;
}

// 已知问题，在视频比较长的时候，获取靠后位置的截图会比较慢
// 打算采取预处理的方式解决，以后再弄
- (void) asycGenerateThumbnailImageAtIndex:(NSInteger)requestIndex
                                    result:(XCFVideoRangeSliderThumbnailBlock)result
{
    NSUInteger totalFrames = [self collectionView:self.frameCollectionView
                           numberOfItemsInSection:0];
    if (requestIndex >= totalFrames || requestIndex < 0) {
        if (result) result(requestIndex,nil);
        return;
    }
    
    // 查询图片缓存
    NSNumber *initKey = @(requestIndex);
    UIImage *resultImage = [self.cachedFrames objectForKey:initKey];
    if (resultImage) {
        if (result) result(requestIndex,resultImage);
        return;
    }
    
    // 查询正在跑的缓存
    id runningTask = [self.runningTasks objectForKey:initKey];
    if (runningTask) {
        if (result) {
            [self.runningTasks setObject:result forKey:initKey];
        }
        
        return;
    }
    
    // 开启新的查询
    NSMutableArray<NSValue*> *requestTimeValues = [NSMutableArray arrayWithCapacity:20];
    for (NSInteger idx = requestIndex;idx < MIN(totalFrames, requestIndex + 20);idx += 1) {
        NSNumber *key = @(idx);
        if ([self.cachedFrames objectForKey:key] || [self.runningTasks objectForKey:key]) continue;
        
        CGFloat width = self.bounds.size.width;
        NSTimeInterval targetSecond = (idx + 0.5) * _videoRangeSliderFrameWidth / width * self.maximumTrimLength;
        targetSecond = MIN(targetSecond, self.videoLength);
        CMTime targetTime = CMTimeMakeWithSeconds(targetSecond, (int32_t)(idx + 1) * 100);
        NSValue *targetTimeValue = [NSValue valueWithCMTime:targetTime];
        
        [requestTimeValues addObject:targetTimeValue];
        
        if (idx == requestIndex) {
            if (result) {
                [self.runningTasks setObject:result forKey:key];
            }
        } else {
            [self.runningTasks setObject:[NSNull null] forKey:key];
        }
    }
    
    __weak typeof(self) weak_self = self;
    [self.imageGenerator generateCGImagesAsynchronouslyForTimes:requestTimeValues completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult r, NSError * _Nullable error) {
        __strong typeof(weak_self) strong_self = weak_self;
        if (r == AVAssetImageGeneratorSucceeded && image && strong_self) {
            NSInteger index = requestedTime.timescale / 100 - 1;
            NSInteger scale = [UIScreen mainScreen].scale;
            UIImage *newImage = [UIImage imageWithCGImage:image scale:scale orientation:UIImageOrientationUp];
            if (newImage) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSNumber *key = @(index);
                    [strong_self.cachedFrames setObject:newImage forKey:key];
                    id task = [strong_self.runningTasks objectForKey:key];
                    if (task && task != [NSNull null]) {
                        XCFVideoRangeSliderThumbnailBlock block = (XCFVideoRangeSliderThumbnailBlock)task;
                        block(index,newImage);
                    }
                    [strong_self.runningTasks removeObjectForKey:key];
                });
            }
        }
    }];
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
    NSInteger count = floor(self.videoLength / self.maximumTrimLength * collectionView.bounds.size.width / _videoRangeSliderFrameWidth);
    return count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    _XCFVideoRangerSliderCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"frameCell"
                                                                                forIndexPath:indexPath];
    NSInteger item = indexPath.item;
    cell.tag = item;
#if ASYNC_GENERATE_IMAGE
    [self asycGenerateThumbnailImageAtIndex:item result:^(NSInteger idx, UIImage *image) {
        if (cell.tag == idx) {
            cell.imageView.image = image;
        }
    }];
#else
    cell.imageView.image = [self generateThumbnailImageAtIndex:item];
#endif
    return cell;
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.frameCollectionView && !super.isTracking) {
        CGFloat offset = self.frameCollectionView.contentOffset.x;
        NSTimeInterval time = offset / scrollView.bounds.size.width * self.maximumTrimLength;
        time = MAX(MIN(time, self.videoLength - self.currentRange.length),0);
//        if (time != self.currentRange.location) {
            XCFVideoRange newRange = self.currentRange;
            newRange.location = time;
            _currentRange = newRange;
            [self sendActionsForControlEvents:UIControlEventValueChanged];
//        }
    }
}

- (void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (scrollView == self.frameCollectionView && !super.isTracking && !decelerate) {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView == self.frameCollectionView && !super.isTracking) {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(_videoRangeSliderFrameWidth, collectionView.bounds.size.height);
}

#pragma mark - touch event

- (void) sendActionsForControlEvents:(UIControlEvents)controlEvents
{
    if (controlEvents & UIControlEventValueChanged) {
        if ([NSThread isMainThread]) {
            [super sendActionsForControlEvents:controlEvents];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [super sendActionsForControlEvents:controlEvents];
            });
        }
    }
}

- (BOOL) isTracking
{
    return
    ([super isTracking] && CGRectContainsPoint(self.bounds, _trackInitPoint)) ||
    self.frameCollectionView.isDragging ||
    self.frameCollectionView.isDecelerating;
}

- (UIView *) hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGRect sliderTouchRect = CGRectInset(self.slider.frame, -20, 0);
    if (CGRectContainsPoint(sliderTouchRect, point)) {
        return self;
    } else if (CGRectContainsPoint(self.frameCollectionView.frame, point)) {
        return self.frameCollectionView;
    } else {
        return nil;
    }
}

- (BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (self.videoLength < self.minimumTrimLength) return NO;
    
    CGPoint point = [touch locationInView:self];
    _trackInitPoint = point;
    _trackInitRange = self.currentRange;
    UIView *hit = [self hitTest:point withEvent:event];
    return hit && hit == self;
}

- (BOOL) continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint point = [touch locationInView:self];
    CGFloat distance = point.x - _trackInitPoint.x;
    NSTimeInterval interval = distance / self.bounds.size.width * self.maximumTrimLength;
    NSTimeInterval newLength = _trackInitRange.length + interval;
    newLength = MIN(MAX(newLength, self.minimumTrimLength),[self _actualMaximumTrimLength]);
    
//    if (newLength != self.currentRange.length) {
        XCFVideoRange newRange = self.currentRange;
        newRange.length = newLength;
        if (newRange.location + newRange.length > self.videoLength) {
            newRange.location = self.videoLength - newRange.length;
        }
        
        _currentRange = newRange;
        [self updateOverlayViewLayout];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
//    }
    
    return YES;
}

- (void) cancelTrackingWithEvent:(UIEvent *)event
{
    _trackInitPoint.x = self.bounds.origin.x - 1;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void) endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    _trackInitPoint.x = self.bounds.origin.x - 1;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end
