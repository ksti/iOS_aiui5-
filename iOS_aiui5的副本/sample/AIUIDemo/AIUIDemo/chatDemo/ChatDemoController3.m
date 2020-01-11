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

#define kVoiceViewHeight 150
#define kWelcome @"你好！我是小洋\n有什么可以帮你吗？"

@interface ChatDemoController3 ()<SSChatKeyBoardInputViewDelegate,UITableViewDelegate,UITableViewDataSource,UIScrollViewDelegate,SSChatBaseCellDelegate>

//聊天列表

@property(nonatomic,strong)NSMutableArray *datas;

@property (strong, nonatomic) UIView    *mBackView;
@property (assign, nonatomic) CGFloat   backViewH;
@property(nonatomic,strong)UITableView *mTableView;
@property(nonatomic,strong)UIView *voiceViewContainer;
@property(nonatomic,strong)UIButton *voiceAndKeyboardButton;
@property(nonatomic,assign)BOOL keyboardShow;

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

@property(nonatomic,assign)AVAudioSessionCategory audioCategory;

@end

@implementation ChatDemoController3 {
    CGFloat _safeTopHeight;
}

-(instancetype)init{
    if(self = [super init]){
        _datas = [NSMutableArray new];
        _chatData = [SSChatDatas new];        
        _chatData.hiddenHeaderImage = YES;
        _chatData.hiddenMessageBackgroundImage = YES;
        _audioCategory = [[AVAudioSession sharedInstance] category];
    }
    return self;
}

//不采用系统的旋转
- (BOOL)shouldAutorotate{
    return NO;
}

-(void)dealloc{
    NSLog(@"%@", @"释放了控制器");
    [[AVAudioSession sharedInstance] setCategory:_audioCategory error:nil];
    [_aiuiAgent destroy];
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
    [self stopPlayer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"~Title3~";
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat closeButtonHeight = 44;
    _safeTopHeight = self.isBeingPresented ? closeButtonHeight : SafeAreaTop_Height; // 如果是模态视图，准备添加一个 44 高度的关闭按钮
    
    if (self.isBeingPresented) {
        UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame) - closeButtonHeight - 30, 0, closeButtonHeight, closeButtonHeight)];
        UIImageView *customImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_close"]];
        customImageView.frame = closeButton.bounds;
        customImageView.contentMode = UIViewContentModeRight;
        [closeButton addSubview:customImageView];
        [closeButton addTarget:self action:@selector(onCloseButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:closeButton];
    }
    
    _mInputView = [SSChatKeyBoardInputView3 new];
    _mInputView.delegate = self;
    [self.view addSubview:_mInputView];
    
    __weak typeof(self) weakSelf = self;
    
    // _mInputView.voiceView
    _mInputView.voiceView.onNlpAnswerText = ^(NSString * _Nonnull answer) {
        if (answer.length > 0) {
            SSChatMessage *message = [weakSelf.chatData generateTextMessageFromId:kFromId text:answer];
            [weakSelf sendMessage:message];
        }
    };
    _mInputView.voiceView.onIatAnswerText = ^(NSString * _Nonnull answer) {
        if (weakSelf.latestMessage != weakSelf.currentMessageFromMe || weakSelf.currentMessageFromMe == nil) {
            weakSelf.currentMessageFromMe = [weakSelf.chatData generateTextMessageFromId:kCurrentId text:answer];
        } else {
            weakSelf.currentMessageFromMe.textString = answer;
        }
        [weakSelf sendContinuousMessage:weakSelf.currentMessageFromMe];
    };
    
    _backViewH = SCREEN_Height-SSChatKeyBoardInputViewH-_safeTopHeight-SafeAreaBottom_Height;
    
    _mBackView = [UIView new];
    _mBackView.frame = CGRectMake(0, _safeTopHeight, SCREEN_Width, _backViewH);
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification object:nil];
    
    [self setupAIUI];

    // 设置语音视图不在随键盘上，如果不设置，默认语音视图在键盘上
    [self setUIType1];
    
    //欢迎语
    [self sendWelcome];
}

// 设置语音视图不在随键盘上
- (void)setUIType1 {
    _mInputView.voiceViewInKeyboard = NO;
    _backViewH = SCREEN_Height-_safeTopHeight-kVoiceViewHeight-SafeAreaBottom_Height;
    _mBackView.frame = CGRectMake(0, _safeTopHeight, SCREEN_Width, _backViewH);
    _mTableView.frame = _mBackView.bounds;
    _mBackView.backgroundColor = UIColor.whiteColor;
    _mTableView.backgroundColor = UIColor.whiteColor;
    self.view.backgroundColor = UIColor.whiteColor;
    _mTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _mTableView.bounds.size.width, 0)];
    __weak typeof(self) weakSelf = self;
    _mInputView.onDismissKeyboard = ^{
        [weakSelf onKeyboardButton:nil];
    };
    [self showKeyboard:NO]; // NO: 默认语音输入，YES: 键盘输入
}

- (void)setupAIUI {
    /*
    // 读取aiui.cfg配置文件
    NSString *cfgFilePath = [[NSBundle mainBundle] pathForResource:@"aiui" ofType:@"cfg"];
    NSString *cfg = [NSString stringWithContentsOfFile:cfgFilePath encoding:NSUTF8StringEncoding error:nil];
    
    _aiuiAgent = [IFlyAIUIAgent createAgent:cfg withListener:self];
    
    IFlyAIUIMessage *wakeuMsg = [[IFlyAIUIMessage alloc]init];
    wakeuMsg.msgType = CMD_WAKEUP;
    
    [_aiuiAgent sendMessage:wakeuMsg];
    */
    _aiuiAgent = _mInputView.voiceView.aiuiAgent; // 用语音录入的 aiuiAgent
}

- (void)onCloseButton:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (UIView *)voiceViewContainer {
    if (_voiceViewContainer == nil) {
        _voiceViewContainer = [UIView new];
        CGFloat containerHeight = kVoiceViewHeight;
        CGFloat buttonHeight = 32;
        CGFloat buttonWidth = 32;
        CGRect containerFrame = CGRectMake(0, self.view.bounds.size.height - containerHeight - SafeAreaBottom_Height, self.view.bounds.size.width, containerHeight);
        if (self.isBeingPresented) {
            containerFrame.origin.y -= StatuBar_Height;
        }
        _voiceViewContainer.frame = containerFrame;
        if (_voiceAndKeyboardButton == nil) {
            UIButton *button = [[UIButton alloc] init];
            CGRect buttonRect = CGRectMake(30, containerHeight/2 - buttonHeight/2, buttonWidth, buttonHeight);
            buttonRect.origin.y = containerHeight/2 - buttonHeight;
            button.frame = buttonRect;
            [button setImage:[UIImage imageNamed:@"icon_keyboard"] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(onKeyboardButton:) forControlEvents:UIControlEventTouchUpInside];
            [_voiceViewContainer addSubview:button];
            _voiceAndKeyboardButton = button;
        }
    }
    return _voiceViewContainer;
}

- (void)showKeyboard:(BOOL)show {
    // 调用 _mInputView 的 showKeyboard
    [_mInputView showKeyboard:show];
    [self.voiceViewContainer setHidden:show];
    if (!show) {
        _mInputView.voiceView.frame = _voiceViewContainer.bounds;
        [_mInputView.voiceView forceResetStatus];
        [self.voiceViewContainer addSubview:_mInputView.voiceView];
        [self.voiceViewContainer bringSubviewToFront:_voiceAndKeyboardButton];
        [self.view addSubview:self.voiceViewContainer];
    }
}

- (void)onKeyboardButton:(UIButton *)sender {
    self.keyboardShow = !self.keyboardShow;
    [self showKeyboard:self.keyboardShow];
}

-(void)addNewMesseage:(SSChatMessage *)message animation:(BOOL)animation{
    self.latestMessage = message;
    if (_mInputView.voiceViewInKeyboard == NO) {
        message.showTime = NO;
    }
    [self willSendMessage:message];
}

-(void)updateTableView:(BOOL)animation{
    [self.mTableView reloadData];
    if(self.datas.count>0){
        NSInteger row = _mInputView.voiceViewInKeyboard ? self.datas.count-1 : MAX(0, (NSInteger)(self.datas.count-2));
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        if (_mInputView.voiceViewInKeyboard == NO) {
            if (self.latestMessage.messageFrom == SSChatMessageFromMe) {
                row = self.datas.count-1;
                indexPath = [NSIndexPath indexPathForRow:row inSection:0];
            }
            SSChatMessagelLayout *layout = self.datas[row];
            CGRect footerViewFrame = self.mTableView.tableFooterView.frame;
            footerViewFrame.size.height = CGRectGetHeight(self.mTableView.frame) - layout.cellHeight;
            if (row == self.datas.count-2) {
                SSChatMessagelLayout *lastLayout = self.datas.lastObject;
                footerViewFrame.size.height -= lastLayout.cellHeight;
            }
            self.mTableView.tableFooterView.frame = footerViewFrame;
            [self.mTableView setTableFooterView:self.mTableView.tableFooterView];
            [self.mTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:animation];
        } else {
            [self.mTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:animation];
        }
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
    if (_mInputView.voiceViewInKeyboard == NO) {
        cell.backgroundColor = UIColor.clearColor;
        cell.contentView.backgroundColor = UIColor.clearColor;
        cell.mBackImgButton.backgroundColor = UIColor.clearColor;
    }
    return cell;
}


//视图归位
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (_mInputView.voiceViewInKeyboard) {
        [_mInputView SetSSChatKeyBoardInputViewEndEditing];
    }
}


-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    if (_mInputView.voiceViewInKeyboard) {
        [_mInputView SetSSChatKeyBoardInputViewEndEditing];
    }
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
        weakSelf.mBackView.frame = CGRectMake(0, _safeTopHeight, SCREEN_Width, height);
        weakSelf.mTableView.frame = self.mBackView.bounds;
        [weakSelf updateTableView:YES];
    } completion:^(BOOL finished) {
        
    }];
}

//照片10 视频11 通话12 位置13 文件14 红包15
//转账16 语音输入17 名片18 活动19
-(void)SSChatKeyBoardInputViewBtnClickFunction:(NSInteger)index{    
    NSLog(@"%@", [NSString stringWithFormat:@"键盘输入非文字消息index: %ld", (long)index]);
}


//发送文本
-(void)SSChatKeyBoardInputViewBtnClick:(NSString *)string{
    [self sendTextToAIUI:string ?: @""];
    SSChatMessage *message = [self.chatData generateTextMessageFromId:kCurrentId text:string];
    message.conversationId = kSessionId;
    [self sendMessage:message];
}

//发送语音
-(void)SSChatKeyBoardInputViewBtnClick:(SSChatKeyBoardInputView3 *)view voicePath:(NSString *)voicePath time:(int)second{

    NSLog(@"%@", voicePath);
    SSChatMessage *message = [self.chatData generateTextMessageFromId:kCurrentId text:@"发来了一段语音"];
    message.conversationId = kSessionId;
    [self sendMessage:message];
}

- (void)sendWelcome {
    SSChatMessage *message = [self.chatData generateTextMessageFromId:kFromId text:kWelcome];
    [self sendMessage:message];
    [self startTTSTest:kWelcome];
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

#pragma mark - private

- (void)stopPlayer{
    IFlyAIUIMessage *msg = [[IFlyAIUIMessage alloc] init];
    msg.msgType = CMD_TTS;
    msg.arg1 = TTS_CANCEL;
    
    [_aiuiAgent sendMessage:msg];
}

- (void)processResult:(IFlyAIUIEvent *)event{
    
    NSString *info = event.info;
    NSData *infoData = [info dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *infoDic = [NSJSONSerialization JSONObjectWithData:infoData options:NSJSONReadingMutableContainers error:&err];
    if(!infoDic){
        NSLog(@"parse error! %@", info);
        return;
    }
    
    NSLog(@"infoDic = %@", infoDic);
    
    NSDictionary *data = [((NSArray *)[infoDic objectForKey:@"data"]) objectAtIndex:0];
    NSDictionary *params = [data objectForKey:@"params"];
    NSDictionary *content = [(NSArray *)[data objectForKey:@"content"] objectAtIndex:0];
    NSString *sub = [params objectForKey:@"sub"];
    
    if([sub isEqualToString:@"tts"]){
        NSString *cnt_id = [content objectForKey:@"cnt_id"];
        if(cnt_id){
            //合成音频数据
            NSData *audioData = [event.data objectForKey:cnt_id];
            
            //当前音频块状态：0（开始）,1（中间）,2（结束）,3（一块）
            int dts = [(NSNumber *)[content objectForKey:@"dts"] intValue];
            
            //合成进度
            int text_per = [(NSNumber *)[content objectForKey:@"text_percent"] intValue];
            
            NSLog(@"dataLen=%lu, dts=%d, text_percent=%d", (unsigned long)[audioData length], dts, text_per);
        }
    }
}

- (void)processTTS:(IFlyAIUIEvent *)event{
    switch (event.arg1) {
        //开始播放或恢复播放回调
        case TTS_SPEAK_BEGIN:
        {
            NSLog(@"Playing");
            NSLog(@"TTS_SPEAK_BEGIN");
        }
            break;
        //此回调sdk内部不会执行，恢复播放全部走TTS_SPEAK_BEGIN回调
        case TTS_SPEAK_RESUMED:
        {
            
        }
            break;
        //播放暂停回调
        case TTS_SPEAK_PAUSED:
        {
            NSLog(@"Paused");
            NSLog(@"TTS_SPEAK_PAUSED");
        }
            break;
        //播放完成回调
        case TTS_SPEAK_COMPLETED:
        {
            int error = event.arg2;
            NSLog(@"%@", [NSString stringWithFormat:@"TTS Completed, error=%d",error]);
            NSLog(@"TTS_SPEAK_COMPLETED, error=%d", error);
        }
            break;
        //播放进度回调
        case TTS_SPEAK_PROGRESS:
        {
            //播放进度
            int percent = [(NSNumber *)[event.data objectForKey:@"percent"] intValue];
            //当前播放文本的起始位置，对于汉字或字母都需／2处理
            int begpos = [(NSNumber *)[event.data objectForKey:@"begpos"] intValue];
            //当前播放文本的结束位置，对于汉字或字母都需／d处理
            int endpos = [(NSNumber *)[event.data objectForKey:@"endpos"] intValue];
            
            NSLog(@"%@", [NSString stringWithFormat:@"PROGRESS:%d",percent]);
            NSLog(@"TTS_SPEAK_PROGRESS, progress=%d, begpos=%d, endpos=%d", percent, begpos, endpos);
        }
            break;
        default:
            break;
    }
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    [self stopPlayer];
    
    NSLog(@"applicationWillResignActive");
}

- (void)startTTSTest:(NSString *)text{
    if (_aiuiAgent == nil)
    {
        NSLog(NSLocalizedString(@"agentNull", nil));
        return;
    }
    //切换为扬声器播放
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    NSData *textData = [text dataUsingEncoding:NSUTF8StringEncoding];
    NSString *params = [NSString stringWithFormat:@"vcn=x_chongchong,engine_type=xtts,speed=50,pitch=50,volume=50"];
    
    IFlyAIUIMessage *msg = [[IFlyAIUIMessage alloc] init];
    msg.msgType = CMD_TTS;
    msg.arg1 = TTS_START;
    msg.params = params;
    msg.data = textData;
    
    [_aiuiAgent sendMessage:msg];
    
    // 测试代码
//    [NSTimer scheduledTimerWithTimeInterval:8
//                                     target:self
//                                   selector:@selector(pauseTTSTest)
//                                   userInfo:nil
//                                    repeats:false];
    
}

- (void)pauseTTSTest{
    if (_aiuiAgent == nil)
    {
        NSLog(NSLocalizedString(@"agentNull", nil));
        return;
    }
    IFlyAIUIMessage *msg = [[IFlyAIUIMessage alloc] init];
    msg.msgType = CMD_TTS;
    msg.arg1 = TTS_PAUSE;
    
    [_aiuiAgent sendMessage:msg];
    [NSTimer scheduledTimerWithTimeInterval:3
                                     target:self
                                   selector:@selector(resumeTTSTest)
                                   userInfo:nil
                                    repeats:false];
}

- (void)resumeTTSTest{
    if (_aiuiAgent == nil)
    {
        NSLog(NSLocalizedString(@"agentNull", nil));
        return;
    }
    IFlyAIUIMessage *msg = [[IFlyAIUIMessage alloc] init];
    msg.msgType = CMD_TTS;
    msg.arg1 = TTS_RESUME;
    
    [_aiuiAgent sendMessage:msg];
    
    [NSTimer scheduledTimerWithTimeInterval:10
                                     target:self
                                   selector:@selector(sendWelcome)
                                   userInfo:nil
                                    repeats:false];
}

- (void)sendTextToAIUI:(NSString *)text {
    //写入文本
    [_mInputView.voiceView sendTextToAIUI:text];
}

#pragma mark - IFlyAIUIListener

- (void) onEvent:(IFlyAIUIEvent *) event {
    switch (event.eventType) {
            
        case EVENT_CONNECTED_TO_SERVER:
        {
            NSLog(@"CONNECT TO SERVER");
        } break;
            
        case EVENT_SERVER_DISCONNECTED:
        {
            NSLog(@"DISCONNECT TO SERVER");
        } break;
            
        case EVENT_STATE:
        {
            switch (event.arg1)
            {
                case STATE_IDLE:
                {
                    NSLog(@"EVENT_STATE: %s", "IDLE");
                } break;
                    
                case STATE_READY:
                {
                    NSLog(@"EVENT_STATE: %s", "READY");
                } break;
                    
                case STATE_WORKING:
                {
                    NSLog(@"EVENT_STATE: %s", "WORKING");
                } break;
            }
        } break;
            
        case EVENT_WAKEUP:
        {
            NSLog(@"EVENT_WAKEUP");
        } break;
            
        case EVENT_SLEEP:
        {
            NSLog(@"EVENT_SLEEP");
        } break;
            
        case EVENT_VAD:
        {
            switch (event.arg1)
            {
                case VAD_BOS:
                {
                    NSLog(@"EVENT_VAD_BOS");
                } break;
                    
                case VAD_EOS:
                {
                    NSLog(@"EVENT_VAD_EOS");
                } break;
                    
                case VAD_VOL:
                {
                    NSString *volume = [[NSString alloc] initWithFormat:@"Volume:%d",event.arg2];
                    NSLog(@"%@", volume);
                } break;
            }
        } break;
            
        case EVENT_RESULT:
        {
            NSLog(@"EVENT_RESULT");
            [self processResult:event];
        } break;
            
        case EVENT_TTS:
        {
            NSLog(@"EVENT_TTS");
            [self processTTS:event];
        } break;
            
        case EVENT_CMD_RETURN:
        {
            NSLog(@"EVENT_CMD_RETURN");
        } break;
            
        case EVENT_ERROR:
        {
            NSString *error = [[NSString alloc] initWithFormat:@"Error Message：%@\nError Code：%d",event.info,event.arg1];
            NSLog(@"EVENT_ERROR: %@",error);
        } break;
    }
    
}

@end
