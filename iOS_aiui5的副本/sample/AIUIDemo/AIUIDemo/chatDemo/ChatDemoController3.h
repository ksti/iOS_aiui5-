//
//  SSChatController.h
//  SSChatView
//
//  Created by soldoros on 2018/9/25.
//  Copyright © 2018年 soldoros. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SSChatMessagelLayout.h"
#import "SSChatViews.h"
#import "IFlyAIUI/IFlyAIUI.h"

@interface ChatDemoController3 : UIViewController<IFlyAIUIListener>

@property IFlyAIUIAgent *aiuiAgent;

@end
