//
//  SSChatKeyBordFunctionView.h
//  SSChatView
//
//  Created by soldoros on 2018/9/25.
//  Copyright © 2018年 soldoros. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SSChatKeyBoardDatas.h"
// AIUI
#import "IFlyAIUI/IFlyAIUI.h"
#import "IFlyAIUILocationRequest.h"

/**
 自定制语音对话视图
*/

@interface CustomVoiceView : UIView<IFlyAIUIListener>

- (void)invalidate;

- (void)resetStatus;
- (void)forceResetStatus;

@property IFlyAIUIAgent *aiuiAgent;

@property (nonatomic, copy) NSString *globalSid;

@property (nonatomic, readwrite) int aiuiState;

@property (nonatomic, readwrite) BOOL autoTTS;

// 地理位置请求对象
@property (nonatomic, strong) IFlyAIUILocationRequest* mLocationRequest;

// AIUI
@property (nonatomic, strong, readonly) NSString *nlpResultText;
@property (nonatomic, strong, readonly) NSString *iatResultText;
@property (nonatomic, strong, readonly) NSString *commandResultText;

@property (nonatomic, strong, readonly) NSString *nlpAnswerText;
@property (nonatomic, strong, readonly) NSString *iatAnswerText;

@property (nonatomic, copy, nullable) void (^onNlpAnswerText)(NSString * _Nonnull answer);
@property (nonatomic, copy, nullable) void (^onIatAnswerText)(NSString * _Nonnull answer);

- (void)sendTextToAIUI:(NSString *_Nonnull)text;

@end
