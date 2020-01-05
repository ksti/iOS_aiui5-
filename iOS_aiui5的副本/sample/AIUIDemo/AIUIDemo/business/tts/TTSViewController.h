/*
 * TTSViewController.h
 * AIUIDemo
 *
 *  Created on: 2018年7月7日
 *      Author: 讯飞AIUI开放平台（http://aiui.xfyun.cn）
 */

#import <UIKit/UIKit.h>
#import "PopupView.h"
#import "IFlyAIUI/IFlyAIUI.h"

@interface TTSViewController : UIViewController<IFlyAIUIListener>

@property IFlyAIUIAgent *aiuiAgent;

@property (nonatomic,strong) PopupView  *popUpView;
@property (nonatomic, copy)  NSString *defaultText;


/* 创建Agent */
@property (weak, nonatomic) IBOutlet UIButton *createAgentBtn;

/* 语音合成内容view*/
@property (weak, nonatomic) IBOutlet UITextView *textView;

/* 开始合成 */
@property (weak, nonatomic) IBOutlet UIButton *startTTS;

/* 停止合成 */
@property (weak, nonatomic) IBOutlet UIButton *stopTTS;

/* 暂停播放 */
@property (weak, nonatomic) IBOutlet UIButton *pauseTTS;

/* 恢复播放*/
@property (weak, nonatomic) IBOutlet UIButton *resumeTTS;

/* 清空文本 */
@property (weak, nonatomic) IBOutlet UIButton *clearText;

@end
