/*
 * UnderstandViewController.h
 * AIUIDemo
 *
 *  Created on: 2018年1月1日
 *      Author: 讯飞AIUI开放平台（http://aiui.xfyun.cn）
 */

#import <UIKit/UIKit.h>
#import "PopupView.h"
#import "IFlyAIUI/IFlyAIUI.h"
#import "IFlyAIUILocationRequest.h"

@class PopupView;


/**
 *demo of Natural Language Understanding (NLP)
 *
 */
@interface UnderstandViewController : UIViewController<IFlyAIUIListener>

@property IFlyAIUIAgent *aiuiAgent;

@property (nonatomic, copy) NSString *globalSid;

@property (nonatomic, readwrite) int aiuiState;

@property (nonatomic, readwrite) BOOL autoTTS;

// 地理位置请求对象
@property (nonatomic, strong) IFlyAIUILocationRequest* mLocationRequest;

@property (nonatomic,strong) PopupView  *popUpView;
@property (nonatomic, copy)  NSString * defaultText;


/* 创建Agent */
@property (weak, nonatomic) IBOutlet UIButton *createAgentBtn;

/* 语音识别、语义理解内容view*/
@property (weak, nonatomic) IBOutlet UITextView *textView;

/* 开始语音识别和语义理解 */
@property (weak, nonatomic) IBOutlet UIButton *startRecordBtn;

/* 停止语音识别和语义理解 */
@property (weak, nonatomic) IBOutlet UIButton *stopRecordBtn;

/* 上传联系人 */
@property (weak, nonatomic) IBOutlet UIButton *upContactsBtn;

/* 打包（上传联系人结果）查询*/
@property (weak, nonatomic) IBOutlet UIButton *packQueryBtn;

/* TTS播报切换*/
@property (weak, nonatomic) IBOutlet UIButton *autoTTSBtn;

/* 销毁Agent */
@property (weak, nonatomic) IBOutlet UIButton *destroyAgentBtn;

@end

