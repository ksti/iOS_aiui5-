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

@property IFlyAIUIAgent *aiuiAgent;

@property (nonatomic, copy) NSString *globalSid;

@property (nonatomic, readwrite) int aiuiState;

@property (nonatomic, readwrite) BOOL autoTTS;

// 地理位置请求对象
@property (nonatomic, strong) IFlyAIUILocationRequest* mLocationRequest;

@end
