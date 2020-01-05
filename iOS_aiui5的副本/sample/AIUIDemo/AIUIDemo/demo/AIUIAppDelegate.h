/*
 * AIUIAppDelegate.h
 *
 *  Created on: 2018年1月1日
 *      Author: 讯飞AIUI开放平台（http://aiui.xfyun.cn）
 */

#import <UIKit/UIKit.h>

@class AIUIViewController;

@interface AIUIAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) AIUIViewController *viewController;

@end
