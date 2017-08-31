//
//  XCFTrieMatchTestDemoController.m
//  XCFKit Demo
//
//  Created by Li Guoyin on 2017/8/31.
//  Copyright © 2017年 XiaChuFang. All rights reserved.
//

#import "XCFTrieMatchTestDemoController.h"
#import <XCFKit/XCFKit.h>

@interface XCFTrieMatchTestDemoController ()<XCFStringKeywordDataProvider>

@property (strong, nonatomic) IBOutlet UITextField *keywordsTextField;
@property (strong, nonatomic) IBOutlet UITextView *matchTextView;
@property (strong, nonatomic) IBOutlet UIButton *matchButton;

@property (nonatomic, assign) BOOL matchCase;

@end

@implementation XCFTrieMatchTestDemoController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.keywordsTextField.text = @"{*}";
    self.matchTextView.text = @"http://www.xiachufang.com?idfa={{IDFA}&version={VERSION}&width={WIDTH}&height={HEIGHT}&flag={FLAG}&name={NAME}&query={OTHER}{NAME}&idfa=__IDFA__hahahahah";
    self.matchTextView.allowsEditingTextAttributes = YES;
    self.matchTextView.backgroundColor = [UIColor xcf_mainBackgroundColor];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.matchCase = YES;
    
    UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.matchButton addGestureRecognizer:gesture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)searchAction:(id)sender {
    NSArray *keywords = [self keywords];
    if (keywords.count == 0) [self.keywordsTextField becomeFirstResponder];
    else if (self.matchTextView.text.length == 0 || self.matchTextView.attributedText.length == 0) [self.matchTextView becomeFirstResponder];
    else {
        [self.view endEditing:YES];
        
        NSString *text = self.matchTextView.text ?: self.matchTextView.attributedText.string;
        
        NS_VALID_UNTIL_END_OF_SCOPE XCFStringKeywordTransformer *t = [XCFStringKeywordTransformer transformerWithWeakDataProviders:@[self]];
        t.matchCase = self.matchCase;
        NSArray<NSTextCheckingResult *> *results = [t searchResultsFromString:text];
        
        NSMutableAttributedString *attributeString =
        [[NSMutableAttributedString alloc] initWithString:text
                                               attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:16],
                                                            NSForegroundColorAttributeName : [UIColor xcf_mainTextColor]}];
        for (NSTextCheckingResult *result in results) {
            [attributeString addAttribute:NSForegroundColorAttributeName value:[UIColor xcf_linkColor] range:result.range];
        }
        
        self.matchTextView.attributedText = attributeString;
    }
}

- (void) longPress:(id)sender
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"sensitive" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.matchCase = YES;
        [self updateButtonTitle];
    }];
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"insensitive" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.matchCase = NO;
        [self updateButtonTitle];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:action1];
    [alert addAction:action2];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) updateButtonTitle
{
    NSString *title = self.matchCase ? @"Match" : @"Match (Insensitive)";
    [self.matchButton setTitle:title forState:UIControlStateNormal];
}

- (IBAction)doneAction:(id)sender {
    [self.view endEditing:YES];
}

- (NSArray<NSString *> *) keywords
{
    return
    [[self.keywordsTextField.text componentsSeparatedByString:@","]
     filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.length > 0"]];
}

- (NSString *) valueForKeyword:(NSString *)keyword
{
    return nil;
}

@end
