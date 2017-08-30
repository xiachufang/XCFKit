//
//  XCFTrieTreeDemoViewController.m
//  XCFKit Demo
//
//  Created by Li Guoyin on 2017/8/29.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import "XCFTrieTreeDemoViewController.h"
#import <XCFKit/XCFStringKeywordTransformer.h>

@interface XCFTrieTreeDemoViewController ()<XCFStringKeywordDataProvider>

@property (strong, nonatomic) IBOutlet UILabel *countLabel;
@property (strong, nonatomic) IBOutlet UITextView *logTextView;
@property (strong, nonatomic) IBOutlet UISlider *slider;

@property (nonatomic, strong) XCFStringKeywordTransformer *transformer;

@end

@implementation XCFTrieTreeDemoViewController

- (void) dealloc
{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self countChanged:self.slider];
    self.logTextView.text = nil;
    
    _transformer = [XCFStringKeywordTransformer transformerWithWeakDataProviders:@[self]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)countChanged:(UISlider *)sender {
    self.countLabel.text = [[NSNumber numberWithInteger:sender.value] stringValue];
}

- (IBAction)runAction:(id)sender {
    NSMutableArray<NSString *> *components = [NSMutableArray new];
    [[self keywords] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [components addObject:[NSString stringWithFormat:@"%tu_%tu_%@",idx,[obj hash],obj]];
    }];
    
    NSString *text = [components componentsJoinedByString:@"&"];
    
    NSMutableString *log = [NSMutableString new];
    NSUInteger count = (NSUInteger)self.slider.value;
    [log appendFormat:@"\nrun %tu times",count];
    
    [log appendFormat:@"\nTrie Tree : "];
    
    NSDate *start = [NSDate date];
    for (int i  = 0;i < count;i++) {
        @autoreleasepool {
            [self.transformer transformString:text];
        }
    }
    NSDate *end = [NSDate date];
    [log appendFormat:@"%lf s",[end timeIntervalSinceDate:start]];
    
    [log appendFormat:@"\nnormal : "];
    
    start = [NSDate date];
    NSArray<NSString *> *keywords = [self keywords];
    for (int i  = 0;i < count;i++) {
        @autoreleasepool {
            NSString *operationText = [text copy];
            for (NSString *word in keywords) {
                NSString *value = [self valueForKeyword:word];
                if (value) {
                    operationText = [operationText stringByReplacingOccurrencesOfString:word withString:value];
                }
            }
        }
    }
    end = [NSDate date];
    [log appendFormat:@"%lf s",[end timeIntervalSinceDate:start]];
    
    self.logTextView.text = log;
}

- (NSArray<NSString *> *) keywords
{
    return @[@"{DEVICE_ID_TYPE}",
             @"{MAC}",
             @"{IDFA}",
             @"{IMEI}",
             @"{ORIGIN}",
             @"{VERSION}",
             @"{PACKAGE_NAME}",
             @"{APP_NAME}",
             @"{SCREEN_WIDTH}",
             @"{SCREEN_HEIGHT}",
             @"{NETWORK}",
             @"{DEVICE_LOCAL_TIME}",
             @"{DEVICE_TYPE}",
             @"{DEVICE_IP}",
             @"{DEVICE_OS}",
             @"{DEVICE_OS_VERSION}",
             @"{LATITUDE}",
             @"{LONGTITUTE}",
             @"{DEVICE_BRAND}",
             @"{DEVICE_MODEL}",
             @"{UA}"];
}

- (NSString *) valueForKeyword:(NSString *)keyword
{
    return [keyword stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"{}"]];
}

@end
