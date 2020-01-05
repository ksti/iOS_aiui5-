/*
 * RootViewController.h
 *
 *  Created on: 2018年1月1日
 *      Author: 讯飞AIUI开放平台（http://aiui.xfyun.cn）
 */

#import <UIKit/UIKit.h>

@class PopupView;

@interface RootViewController : UITableViewController<UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) PopupView * _popUpView;
@property (strong, nonatomic) IBOutlet UITableView *tbView;

@end
