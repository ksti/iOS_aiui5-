//
//  SSChatKeyBordFunctionView.m
//  SSChatView
//
//  Created by soldoros on 2018/9/25.
//  Copyright © 2018年 soldoros. All rights reserved.
//

#import "SSChatKeyBordVoiceView.h"
#import "SSOtherDefine.h"
#import "YYKit.h"


@implementation SSChatKeyBordVoiceView{
    NSArray *titles,*images;
    NSInteger count;
    NSInteger number;
}


-(instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        self.backgroundColor = SSChatCellColor;
        
        UIView *containerView = [UIView new];
        containerView.frame = self.bounds;
        [self addSubview:containerView];
    }
    return self;
    
}


@end
