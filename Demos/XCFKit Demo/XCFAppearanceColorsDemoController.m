//
//  XCFAppearanceColorsDemoController.m
//  XCFKit iOS Demo
//
//  Created by Li Guoyin on 2017/12/12.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import "XCFAppearanceColorsDemoController.h"
#import <XCFKit/UIColor+XCFAppearance.h>
#import <XCFKit/UIColor+Hex.h>
#import <objc/runtime.h>
#import "XCFAppearanceColorCell.h"

@interface _appearanceColor : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) UIColor *color;
@end

@implementation _appearanceColor
@end

@interface XCFAppearanceColorsDemoController ()
<
UICollectionViewDelegateFlowLayout,
UICollectionViewDataSource
>

@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) NSArray<_appearanceColor *> *appearanceColors;

@end

@implementation XCFAppearanceColorsDemoController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableArray<_appearanceColor *> *colors = [NSMutableArray new];
    
    unsigned int methodCount = 0;
    Method *methodList = class_copyMethodList(object_getClass([UIColor class]), &methodCount);
    
    for (int i = 0;i < methodCount;i++) {
        Method method = methodList[i];
        SEL selector = method_getName(method);
        const char *name_c = sel_getName(selector);
        NSString *name = [NSString stringWithUTF8String:name_c];
        
        NSString* const prefix = @"xcf_";
        NSString* const suffix = @"Color";
        if ([name hasPrefix:prefix] && [name hasSuffix:suffix]) {
            name = [name substringWithRange:NSMakeRange(prefix.length, name.length - prefix.length - suffix.length)];
            IMP implementation = method_getImplementation(method);
            UIColor* (*functionPointer)(id, SEL) = (UIColor* (*)(id, SEL))implementation;
            UIColor *color = functionPointer([UIColor class],selector);
            
            if (color) {
                _appearanceColor *_color = [_appearanceColor new];
                _color.name = name;
                _color.color = color;
                [colors addObject:_color];
            }
        }
    }
    
    [colors sortUsingComparator:^NSComparisonResult(_appearanceColor *obj1, _appearanceColor *obj2) {
        return [obj1.name compare:obj2.name];
    }];
    
    _appearanceColors = [colors copy];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _appearanceColors.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSString *identifier = @"colorCell";
    XCFAppearanceColorCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier
                                                                             forIndexPath:indexPath];
    
    _appearanceColor *color = _appearanceColors[indexPath.item];
    
    cell.colorNameLabel.text = color.name;
    cell.colorNameLabel.textColor = [UIColor xcf_contrastColorWithColor:color.color];
    cell.colorHexValueLabel.text = [[UIColor xcf_hexStringWithColor:color.color] uppercaseString];
    cell.colorHexValueLabel.textColor = cell.colorNameLabel.textColor;
    cell.contentView.backgroundColor = color.color;
    
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize) collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
   sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize size;
    size.width = collectionView.bounds.size.width / 2;
    size.height = size.width;
    
    return size;
}

- (UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsZero;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

@end
