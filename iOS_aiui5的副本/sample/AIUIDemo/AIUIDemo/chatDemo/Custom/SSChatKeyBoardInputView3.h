//
//  SSChatKeyBoardInputView.h
//  SSChatView
//
//  Created by soldoros on 2018/9/25.
//  Copyright © 2018年 soldoros. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "SSChatKeyBoardInputView.h"
#import "CustomVoiceView.h"

#define SSChatBtnCounts 1
#define SSChatBtnSpaces (SSChatBtnCounts + 2)
#define SSChatTextWidth2 SCREEN_Width - (SSChatBtnCounts * SSChatBtnSize + SSChatBtnSpaces *  SSChatBtnDistence) //输入框的宽度


@interface SSChatKeyBoardInputView3 : UIView<UITextViewDelegate,AVAudioRecorderDelegate,SSChatKeyBordViewDelegate>

@property(nonatomic,weak)id<SSChatKeyBoardInputViewDelegate>delegate;

//当前的编辑状态（默认 语音 编辑文本 发送表情 其他功能）
@property(nonatomic,assign)SSChatKeyBoardStatus keyBoardStatus;

//键盘或者 表情视图 功能视图的高度
@property(nonatomic,assign)CGFloat changeTime;
@property(nonatomic,assign)CGFloat keyBoardHieght;

//传入底部视图进行frame布局
@property (strong, nonatomic) SSChatKeyBordView   *mKeyBordView;

//顶部线条
@property(nonatomic,strong) UIView   *topLine;

//当前点击的按钮  左侧按钮   表情按钮  添加按钮
@property(nonatomic,strong) UIButton *currentBtn;
@property(nonatomic,strong) UIButton *mLeftBtn;
@property(nonatomic,strong) UIButton *mSymbolBtn;
@property(nonatomic,strong) UIButton *mAddBtn;

//输入框背景 输入框 缓存输入的文字
@property(nonatomic,strong) UIButton     *mTextBtn;
@property(nonatomic,strong) UITextView   *mTextView;
@property(nonatomic,strong) NSString     *textString;
//输入框的高度
@property(nonatomic,assign) CGFloat          textH;

//添加表情
@property(nonatomic,strong) NSObject         *emojiText;

//录音相关
@property(nonatomic, strong) SSChatAudioIndicator *audioIndicator;

//键盘归位
-(void)SetSSChatKeyBoardInputViewEndEditing;

// 自定义录音视图
@property(nonatomic, strong, readonly) CustomVoiceView *voiceView;


@end







