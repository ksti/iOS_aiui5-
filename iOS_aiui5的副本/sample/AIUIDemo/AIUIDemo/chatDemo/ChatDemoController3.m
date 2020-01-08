//
//  SSChatController.m
//  SSChatView
//
//  Created by soldoros on 2018/9/25.
//  Copyright © 2018年 soldoros. All rights reserved.
//

//if (IOS7_And_Later) {
//    self.automaticallyAdjustsScrollViewInsets = NO;
//}

#import "ChatDemoController3.h"
#import "SSChatKeyBoardInputView3.h"
#import "SSAddImage.h"
#import "SSChatBaseCell.h"
#import "SSKit.h"


@interface ChatDemoController3 ()<SSChatKeyBoardInputViewDelegate,UITableViewDelegate,UITableViewDataSource,UIScrollViewDelegate,SSChatBaseCellDelegate>

//聊天列表
@property (strong, nonatomic) UIView    *mBackView;
@property (assign, nonatomic) CGFloat   backViewH;
@property(nonatomic,strong)UITableView *mTableView;
@property(nonatomic,strong)NSMutableArray *datas;
//多媒体键盘
@property(nonatomic,strong)SSChatKeyBoardInputView3 *mInputView;
//访问相册+摄像头
@property(nonatomic,strong)SSAddImage *mAddImage;
//当前用户
@property(nonatomic,strong)NSString *currentUser;
//数据模型
@property(nonatomic,strong)SSChatDatas *chatData;

//开始翻页的messageId
@property(nonatomic,strong)NSString *startMsgId;

//当前最后一个“我”发的消息
@property(nonatomic,strong)SSChatMessage *currentMessageFromMe;
//当前最后一个消息
@property(nonatomic,strong)SSChatMessage *latestMessage;

@end

@implementation ChatDemoController3

-(instancetype)init{
    if(self = [super init]){
        _datas = [NSMutableArray new];
        _chatData = [SSChatDatas new];        
        _chatData.hiddenHeaderImage = YES;
        _chatData.hiddenMessageBackgroundImage = YES;
    }
    return self;
}

//不采用系统的旋转
- (BOOL)shouldAutorotate{
    return NO;
}

-(void)dealloc{
    cout(@"释放了控制器");
    _mInputView.delegate = nil;
    _mInputView = nil;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBar.translucent = YES;
    
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = YES;
    self.navigationController.navigationBar.translucent = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"~Title3~";
    self.view.backgroundColor = [UIColor whiteColor];
    
    _mInputView = [SSChatKeyBoardInputView3 new];
    _mInputView.delegate = self;
    [self.view addSubview:_mInputView];
    
    __weak typeof(self) weakSelf = self;
    _mInputView.voiceView.onNlpAnswerText = ^(NSString * _Nonnull answer) {
        SSChatMessage *message = [weakSelf.chatData generateTextMessageFromId:kFromId text:answer];
        [weakSelf sendMessage:message];
    };
    _mInputView.voiceView.onIatAnswerText = ^(NSString * _Nonnull answer) {
        if (weakSelf.latestMessage != weakSelf.currentMessageFromMe || weakSelf.currentMessageFromMe == nil) {
            weakSelf.currentMessageFromMe = [weakSelf.chatData generateTextMessageFromId:kCurrentId text:answer];
        } else {
            weakSelf.currentMessageFromMe.textString = answer;
        }
        [weakSelf sendContinuousMessage:weakSelf.currentMessageFromMe];
    };
    
    _backViewH = SCREEN_Height-SSChatKeyBoardInputViewH-SafeAreaTop_Height-SafeAreaBottom_Height;
    
    _mBackView = [UIView new];
    _mBackView.frame = CGRectMake(0, SafeAreaTop_Height, SCREEN_Width, _backViewH);
    _mBackView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.mBackView];
    
    _mTableView = [[UITableView alloc]initWithFrame:_mBackView.bounds style:UITableViewStylePlain];
    _mTableView.dataSource = self;
    _mTableView.delegate = self;
    _mTableView.backgroundColor = SSChatCellColor;
    _mTableView.backgroundView.backgroundColor = SSChatCellColor;
    [_mBackView addSubview:self.mTableView];
    _mTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _mTableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    _mTableView.scrollIndicatorInsets = _mTableView.contentInset;
    
    if (@available(iOS 11.0, *)){
        _mTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        _mTableView.estimatedRowHeight = 0;
        _mTableView.estimatedSectionHeaderHeight = 0;
        _mTableView.estimatedSectionFooterHeight = 0;
    }
    
    [_mTableView registerClass:NSClassFromString(@"SSChatTextCell") forCellReuseIdentifier:SSChatTextCellId];
}


-(void)addNewMesseage:(SSChatMessage *)message animation:(BOOL)animation{
    self.latestMessage = message;
    [self willSendMessage:message];
}

-(void)updateTableView:(BOOL)animation{
    [self.mTableView reloadData];
    if(self.datas.count>0){
        NSIndexPath *indexPath = [NSIndexPath     indexPathForRow:self.datas.count-1 inSection:0];
        [self.mTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:animation];
    }
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _datas.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [(SSChatMessagelLayout *)_datas[indexPath.row] cellHeight];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    SSChatMessagelLayout *layout = _datas[indexPath.row];
    SSChatBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:layout.chatMessage.cellString];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.delegate = self;
    cell.indexPath = indexPath;
    cell.layout = layout;
    return cell;
}


//视图归位
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [_mInputView SetSSChatKeyBoardInputViewEndEditing];
}


-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [_mInputView SetSSChatKeyBoardInputViewEndEditing];
}

#pragma SSChatKeyBoardInputViewDelegate 底部输入框代理回调
//点击按钮视图frame发生变化 调整当前列表frame
-(void)SSChatKeyBoardInputViewHeight:(CGFloat)keyBoardHeight changeTime:(CGFloat)changeTime{
    
    if (_mInputView.keyBoardStatus == SSChatKeyBoardStatusEdit && _mInputView.mKeyBordView.type == KeyBordViewFouctionCustom) {
        [_mInputView.voiceView resetStatus];
    }
 
    CGFloat height = _backViewH - keyBoardHeight;
     __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:changeTime animations:^{
        weakSelf.mBackView.frame = CGRectMake(0, SafeAreaTop_Height, SCREEN_Width, height);
        weakSelf.mTableView.frame = self.mBackView.bounds;
        [weakSelf updateTableView:YES];
    } completion:^(BOOL finished) {
        
    }];
}

//照片10 视频11 通话12 位置13 文件14 红包15
//转账16 语音输入17 名片18 活动19
-(void)SSChatKeyBoardInputViewBtnClickFunction:(NSInteger)index{    
    cout([NSString stringWithFormat:@"键盘输入非文字消息index: %ld", (long)index]);
}


//发送文本
-(void)SSChatKeyBoardInputViewBtnClick:(NSString *)string{
    
    SSChatMessage *message = [self.chatData generateTextMessageFromId:kCurrentId text:string];
    message.conversationId = kSessionId;
    [self sendMessage:message];
}

//发送语音
-(void)SSChatKeyBoardInputViewBtnClick:(SSChatKeyBoardInputView3 *)view voicePath:(NSString *)voicePath time:(int)second{

    cout(voicePath);
    SSChatMessage *message = [self.chatData generateTextMessageFromId:kCurrentId text:@"发来了一段语音"];
    message.conversationId = kSessionId;
    [self sendMessage:message];
}

//发送消息
-(void)sendMessage:(SSChatMessage *)message{
    [self addNewMesseage:message animation:NO];
//    // 测试代码
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        //
//        [self addNewMesseage:[self.chatData generateTextMessageFromId:kFromId text:@"测试回复"] animation:YES];
//    });
}

//发送消息
-(void)sendContinuousMessage:(SSChatMessage *)message{
    if (message.messageFrom == SSChatMessageFromMe) {
        if (self.currentMessageFromMe == message) {
            [self updateCurrentMessage:self.currentMessageFromMe];
            if (self.latestMessage == self.currentMessageFromMe) return;
        }
    }
    [self addNewMesseage:message animation:NO];
}

//更新消息
-(void)updateCurrentMessage:(SSChatMessage *)message{
    for(int i=0;i<self.datas.count;++i){
        
        SSChatMessagelLayout *layout = self.datas[i];
        NSString *messageId = layout.chatMessage.messageId;
        
        if([messageId isEqualToString:message.messageId]){
            // 创建 layout 用 [self.chatData getLayoutWithMessage:message]
            SSChatMessagelLayout *newLayout = [self.chatData getLayoutWithMessage:message];
            [self.datas replaceObjectAtIndex:i withObject:newLayout];
            break;
        }
    }
    [self.mTableView reloadData];
}

#pragma mark - NIMChatManagerDelegate
//接收到消息 并设置已读
-(void)onRecvMessages:(NSArray<SSChatMessage *> *)messages{
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_queue_create(0, 0), ^{
        NSArray *layouts = [weakSelf.chatData getLayoutsWithMessages:messages sessionId:kSessionId];
        [weakSelf.datas addObjectsFromArray:layouts];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateTableView:YES];
        });
    });
}

- (void)update:(NSIndexPath *)indexPath
{
    SSChatBaseCell *cell = (SSChatBaseCell *)[self.mTableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        [self.mTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        CGFloat scrollOffsetY = self.mTableView.contentOffset.y;
        [self.mTableView setContentOffset:CGPointMake(self.mTableView.contentOffset.x, scrollOffsetY) animated:NO];
    }
}

//消息即将发送 更新本地列表
-(void)willSendMessage:(SSChatMessage *)message{
    SSChatMessagelLayout *layout = [self.chatData getLayoutWithMessage:message];
    [self.datas addObject:layout];
    [self updateTableView:YES];
}

//消息发送完成 刷新本地列表
-(void)sendMessage:(SSChatMessage *)message didCompleteWithError:(NSError *)error{
    [self updateCurrentMessage:message];
}

@end
