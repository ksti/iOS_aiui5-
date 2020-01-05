//
//  SSChatDatas.m
//  SSChatView
//
//  Created by soldoros on 2018/9/25.
//  Copyright © 2018年 soldoros. All rights reserved.
//


#import "SSChatDatas.h"
#import <UserNotifications/UserNotifications.h>
#import "SSChatTime.h"


@implementation SSChatDatas

-(instancetype)init{
    if(self = [super init]){
        _timelInterval = -1;
    }
    return self;
}


//处理消息的时间显示
-(void)dealTimeWithMessageModel:(SSChatMessage *)model{
    SSChatMessage *message = model;
    CGFloat interval = (_timelInterval - model.timestamp) / 1000;
    if (_timelInterval < 0 || interval > 60 || interval < -60) {
        message.messageTime = [SSChatTime formattedTimeFromTimeInterval:model.timestamp];
        _timelInterval = model.timestamp;
        message.showTime = YES;
    }
}

//网易模型数组转本地layout数组
-(NSMutableArray *)getLayoutsWithMessages:(NSArray *)aMessages sessionId:(NSString *)sessionId{
    
    NSMutableArray *array = [NSMutableArray new];
    for(SSChatMessage *message in aMessages){
        
        if([message.conversationId isEqualToString:sessionId]){
            SSChatMessagelLayout *layout = [[SSChatMessagelLayout alloc]initWithMessage:message];
            [array addObject:layout];
        }
    }
    return  array;
}

//model转layout
-(SSChatMessagelLayout *)getLayoutWithMessage:(NSObject *)message{
    SSChatMessage *chatMessage = (SSChatMessage *)message;
    if ([message isKindOfClass:NSDictionary.class]) {
        chatMessage = [self getModelWithMessage:(NSDictionary *)message];
    }
    SSChatMessagelLayout *layout = [[SSChatMessagelLayout alloc]initWithMessage:chatMessage];
    if (self.hiddenHeaderImage) {
        [layout hideHeaderImage];
    }
    return layout;
}


//网易IM模型转本地模型
-(SSChatMessage *)getModelWithMessage:(NSDictionary *)message{
    
    SSChatMessage *chatMessage = [SSChatMessage new];
    chatMessage.message = message;
    if ([message[@"timestamp"] isKindOfClass:NSNumber.class]) {
        chatMessage.timestamp = [message[@"timestamp"] longLongValue];
    }
    [self dealTimeWithMessageModel:chatMessage];
    
    NSString *currentId = kCurrentId;
    
    if([message[@"from"] isEqualToString:currentId]){
        chatMessage.messageFrom = SSChatMessageFromMe;
        chatMessage.backImgString = self.hiddenMessageBackgroundImage ? @"" : @"icon_qipao1";
        
        chatMessage.voiceImg = [UIImage imageNamed:@"chat_animation_white3"];
        chatMessage.voiceImgs =
        @[[UIImage imageNamed:@"chat_animation_white1"],
          [UIImage imageNamed:@"chat_animation_white2"],
          [UIImage imageNamed:@"chat_animation_white3"]];
    }else{
        chatMessage.messageFrom = SSChatMessageFromOther;
        chatMessage.backImgString = self.hiddenMessageBackgroundImage ? @"" : @"icon_qipao2";
        
        chatMessage.voiceImg = [UIImage imageNamed:@"chat_animation3"];
        chatMessage.voiceImgs =
        @[[UIImage imageNamed:@"chat_animation1"],
          [UIImage imageNamed:@"chat_animation2"],
          [UIImage imageNamed:@"chat_animation3"]];
    }
    
    if ([message[@"messageType"] isEqualToString:@"text"]) {
        chatMessage.textColor   = SSChatTextColor;
        chatMessage.cellString  = SSChatTextCellId;
        chatMessage.messageType = SSChatMessageTypeText;
        chatMessage.textString  = message[@"text"];
    }
    
    return chatMessage;
}


//创建并配置模型
-(SSChatMessage *)generateTextMessageFromId:(NSString *)fromId text:(NSString *)text {
    
    NSDictionary *message = @{
        @"from": fromId ?: kCurrentId,
        @"messageType": @"text",
        @"text": text ?: @"",
    };
    
    return [self getModelWithMessage:message];
}


@end
