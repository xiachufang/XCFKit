//
//  XCFAddEventHeaderView.m
//  xcf-iphone
//
//  Created by Alex on 2016/12/12.
//  Copyright © 2016年 Xiachufang. All rights reserved.
//

#import "XCFAddEventTextView.h"
#import "UIFont+fontWeight.h"
#import "UIColor+XCFAppearance.h"

#define kSeparator @"、"

@interface XCFAddEventTextView () <UITextViewDelegate>

@property (nonatomic, strong) NSMutableOrderedSet <id <XCFAddEventProtocol>> *selectedEvents;

@end

@implementation XCFAddEventTextView

- (void)awakeFromNib{
    [super awakeFromNib];
    self.delegate = self;
    self.allowsEditingTextAttributes = YES;
    self.typingAttributes = self.selectedTextAttributes;
}

- (void)setEvents:(NSArray<id<XCFAddEventProtocol>> *)events{
    if (events && events.count > 0) {
        self.selectedEvents = [[NSMutableOrderedSet alloc]initWithArray:events];
    }else{
        self.selectedEvents = [NSMutableOrderedSet new];
    }
    [self changeTextInTextView];
}

- (NSArray<id<XCFAddEventProtocol>> *)events{
    return [self.selectedEvents copy];
}

- (void)textViewDidChange:(UITextView *)textView{
    NSRange separatorRange = [textView.text rangeOfString:kSeparator options:NSBackwardsSearch];
    if (self.textViewHeightChangedBlock) {
        self.textViewHeightChangedBlock([self measuredSize].height);
    }
    if (self.searchKeyWordChangedBlock) {
        if (separatorRange.location == NSNotFound && textView.text.length > 0){
            self.searchKeyWordChangedBlock(textView.text);
        }else if(separatorRange.location != NSNotFound && textView.text.length - separatorRange.location - separatorRange.length > 0) {
            NSString *inputText = [textView.text substringWithRange:NSMakeRange(separatorRange.location+separatorRange.length, textView.text.length-separatorRange.location-separatorRange.length)];
            self.searchKeyWordChangedBlock(inputText);
        }else{
            self.searchKeyWordChangedBlock(@"");
        }
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(nonnull NSString *)text{
    if (text.length == 0 && range.length > 0) {
        NSInteger namesLength = 0;
        for (int i = 0; i < self.selectedEvents.count; i++) {
            id <XCFAddEventProtocol> obj = [self.selectedEvents objectAtIndex:i];
            if (range.location > namesLength && range.location < namesLength + obj.eventName.length + 1) {
                [self deleteSelectedEventWithIndex:i];
                return NO;
            }
            namesLength = namesLength + obj.eventName.length;
        }
    }
    self.allowsEditingTextAttributes = YES;
    self.typingAttributes = self.inputTextAttributes;
    return ![text isEqualToString:kSeparator];
}

- (void)deleteSelectedEventWithIndex:(NSInteger)index{
    [self.selectedEvents removeObjectAtIndex:index];
    if (self.eventDeletedBlock) {
        self.eventDeletedBlock(index);
    }
}

- (void)changeTextInTextView{
    NSString *eventNamesWithSeparator = @"";
    for (id <XCFAddEventProtocol> obj in self.selectedEvents) {
        eventNamesWithSeparator = [NSString stringWithFormat:@"%@%@%@",eventNamesWithSeparator,obj.eventName,kSeparator];
    }
    
    NSString *inputText = @"";
    NSRange lastSeparatorRange = [self.text rangeOfString:kSeparator options:NSBackwardsSearch];
    if (lastSeparatorRange.location == NSNotFound) {
        inputText = self.text;
    }else{
        NSRange lastSeparatorRange = [self.text rangeOfString:kSeparator options:NSBackwardsSearch];
        NSRange inputTextRange = NSMakeRange(lastSeparatorRange.location + lastSeparatorRange.length ,self.text.length - lastSeparatorRange.location - lastSeparatorRange.length);
        inputText = [self.text substringWithRange:inputTextRange];
    }
    
    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithFormat:@"%@%@",eventNamesWithSeparator,inputText]];
    [attributeStr addAttributes:self.selectedTextAttributes range:NSMakeRange(0, eventNamesWithSeparator.length)];
    [attributeStr addAttributes:self.inputTextAttributes range:NSMakeRange(eventNamesWithSeparator.length, inputText.length)];
    self.attributedText = attributeStr;
    if (self.textViewHeightChangedBlock) {
        self.textViewHeightChangedBlock([self measuredSize].height);
    }
}

- (NSDictionary *)selectedTextAttributes{
    if (!_selectedTextAttributes) {
        _selectedTextAttributes = [self.class defaultSelectedTextAttributes];
    }
    return _selectedTextAttributes;
}

-(CGSize)measuredSize {
    CGSize size = [self systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    if (size.height < 50) {
        size.height = 50;
    }
    return size;
}

+ (NSDictionary *)defaultSelectedTextAttributes{
    static NSDictionary *attributes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIFont *defaultFont = [UIFont xcf_lightSystemFontWithSize:17];
        attributes = @{NSFontAttributeName : defaultFont,
                       NSForegroundColorAttributeName : [UIColor xcf_linkColor]};
    });
    return attributes;
}

- (NSDictionary *)inputTextAttributes{
    if (!_inputTextAttributes) {
        _inputTextAttributes = [self.class defaultInputTextAttributes];
    }
    return _inputTextAttributes;
}

+ (NSDictionary *)defaultInputTextAttributes{
    static NSDictionary *attributes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIFont *defaultFont = [UIFont xcf_lightSystemFontWithSize:17];
        attributes = @{NSFontAttributeName : defaultFont,
                       NSForegroundColorAttributeName : [UIColor xcf_mainTextColor]};
    });
    return attributes;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
@end
