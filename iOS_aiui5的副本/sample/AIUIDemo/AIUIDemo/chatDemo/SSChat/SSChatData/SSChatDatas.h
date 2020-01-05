//
//  SSChatDatas.h
//  SSChatView
//
//  Created by soldoros on 2018/9/25.
//  Copyright © 2018年 soldoros. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SSChatMessagelLayout.h"

#define kCurrentId @"I"
#define kFromId @"Siri"
#define kSessionId @"S"


@interface SSChatDatas : NSObject



/**
 发送消息或者接受消息的时间 初始化-1 代表直接显示时间
 往后超过或等于5分钟就显示见识
 */
@property(nonatomic,assign)NSTimeInterval timelInterval;


/**
 环信消息转本地模型
 
 @param message 传入环信消息
 @return 转换模型
 */
-(SSChatMessage *)getModelWithMessage:(NSDictionary *)message;

/**
 创建并配置模型
 
 @param fromId 传入发信人id
 @param text 消息文本
 @return 返回 SSChatMessage
*/
-(SSChatMessage *)generateTextMessageFromId:(NSString *)fromId text:(NSString *)text;

/**
 将环信消息模型转换成 SSChatMessagelLayout

 @param message 传入环信消息
 @return 返回 SSChatMessagelLayout
 */
-(SSChatMessagelLayout *)getLayoutWithMessage:(SSChatMessage *)message;


/**
 加载所有的消息并转换成layout数组
 
 @param aMessages 传入获取的会话消息数组
 @param sessionId 检测是否是当前会话id的数据
 @return 返回layout数组
 */
-(NSMutableArray *)getLayoutsWithMessages:(NSArray *)aMessages sessionId:(NSString *)sessionId;



/**
 消息发送进度回调

 @param progress 进度
 */
typedef void (^Progress)(int progress);


/**
 发送消息结果回调

 @param layout 消息体
 @param error 发送失败和失败的原因
 */
typedef void (^Completion)(SSChatMessagelLayout *layout, NSError *error);

@property(nonatomic,assign)BOOL hiddenHeaderImage;
@property(nonatomic,assign)BOOL hiddenMessageBackgroundImage;


@end
