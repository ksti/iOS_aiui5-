/*
 * PopupView.h
 * AIUIDemo
 *
 *  Created on: 2018年1月1日
 *      Author: 讯飞AIUI开放平台（http://aiui.xfyun.cn）
 */

#import <UIKit/UIKit.h>

@interface PopupView : UIView

@property (nonatomic,strong) UILabel *textLabel;
@property (nonatomic,strong) UIView*  ParentView;
@property (nonatomic,assign) int queueCount;


/**
 initialize popUpView
 **/
- (id)initWithFrame:(CGRect)frame withParentView:(UIView*)view;


/**
 show text
 **/
- (void)showText:(NSString *)text;


/**
 set text
 **/
- (void)setText:(NSString *) text;//deprecated..

@end
