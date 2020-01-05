//
//  TTSViewController.m
//  AIUIDemo
//
//  Created by jmli3 on 2018/7/7.
//

#import "TTSViewController.h"


@interface TTSViewController ()

@end

@implementation TTSViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    _textView.layer.borderWidth = 0.5f;
    _textView.layer.borderColor = [[UIColor whiteColor] CGColor];
    [_textView.layer setCornerRadius:7.0f];
    
    _defaultText = NSLocalizedString(@"text_tts", nil);
    _textView.text = [NSString stringWithFormat:@"%@",self.defaultText];
    
    UIBarButtonItem *spaceBtnItem= [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem * hideBtnItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"hide", @"Hide") style:UIBarButtonItemStylePlain target:self action:@selector(onKeyBoardDown:)];
    [hideBtnItem setTintColor:[UIColor whiteColor]];
    
    UIToolbar * toolbar = [[ UIToolbar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    toolbar.barStyle = UIBarStyleBlackTranslucent;
    NSArray * array = [NSArray arrayWithObjects:spaceBtnItem,hideBtnItem, nil];
    [toolbar setItems:array];
    _textView.inputAccessoryView = toolbar;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    CGFloat posY = self.textView.frame.origin.y+self.textView.frame.size.height/6;
    _popUpView = [[PopupView alloc] initWithFrame:CGRectMake(100, posY, 0, 0) withParentView:self.view];
    
    [super viewWillAppear:animated];
    
    NSLog(@"viewWillAppear");
}

- (void)viewWillDisappear:(BOOL)animated
{
    _popUpView = nil;
    [self stopPlayer];
    
    [super viewWillDisappear:animated];
    
    NSLog(@"viewWillDisappear");
}

- (IBAction)onStartBtnHandler:(id)sender{
    if (_aiuiAgent == nil)
    {
        [_popUpView showText:NSLocalizedString(@"agentNull", nil)];
        return;
    }
    NSData *textData = [self.textView.text dataUsingEncoding:NSUTF8StringEncoding];
    NSString *params = [NSString stringWithFormat:@"vcn=x_chongchong,engine_type=xtts,speed=50,pitch=50,volume=50"];
    
    IFlyAIUIMessage *msg = [[IFlyAIUIMessage alloc] init];
    msg.msgType = CMD_TTS;
    msg.arg1 = TTS_START;
    msg.params = params;
    msg.data = textData;
    
    [_aiuiAgent sendMessage:msg];
}

- (IBAction)onStopBtnHandler:(id)sender{
    if (_aiuiAgent == nil)
    {
        [_popUpView showText:NSLocalizedString(@"agentNull", nil)];
        return;
    }
    [self stopPlayer];
}

- (IBAction)onPauseBtnHandler:(id)sender{
    if (_aiuiAgent == nil)
    {
        [_popUpView showText:NSLocalizedString(@"agentNull", nil)];
        return;
    }
    IFlyAIUIMessage *msg = [[IFlyAIUIMessage alloc] init];
    msg.msgType = CMD_TTS;
    msg.arg1 = TTS_PAUSE;
    
    [_aiuiAgent sendMessage:msg];
}

- (IBAction)onResumeBtnHandler:(id)sender{
    if (_aiuiAgent == nil)
    {
        [_popUpView showText:NSLocalizedString(@"agentNull", nil)];
        return;
    }
    IFlyAIUIMessage *msg = [[IFlyAIUIMessage alloc] init];
    msg.msgType = CMD_TTS;
    msg.arg1 = TTS_RESUME;
    
    [_aiuiAgent sendMessage:msg];
}

- (IBAction)onClearBtnHandler:(id)sender{
    [_textView setText:@""];
}

- (IBAction)onCreateBtnHandler:(id)sender{
    // 读取aiui.cfg配置文件
    NSString *cfgFilePath = [[NSBundle mainBundle] pathForResource:@"aiui" ofType:@"cfg"];
    NSString *cfg = [NSString stringWithContentsOfFile:cfgFilePath encoding:NSUTF8StringEncoding error:nil];
    
    _aiuiAgent = [IFlyAIUIAgent createAgent:cfg withListener:self];
    
    IFlyAIUIMessage *wakeuMsg = [[IFlyAIUIMessage alloc]init];
    wakeuMsg.msgType = CMD_WAKEUP;
    
    [_aiuiAgent sendMessage:wakeuMsg];
    
    //测试使用
    //[self startTTSTest];
}

- (IBAction)onDestroyBtnHandler:(id)sender{
    if (_aiuiAgent == nil)
    {
        [_popUpView showText:NSLocalizedString(@"agentNull", nil)];
        return;
    }
    [_aiuiAgent destroy];
    
    [self stopPlayer];
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
            [_popUpView showText:@"Playing"];
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
            [_popUpView showText:@"Paused"];
            NSLog(@"TTS_SPEAK_PAUSED");
        }
            break;
        //播放完成回调
        case TTS_SPEAK_COMPLETED:
        {
            int error = event.arg2;
            [_popUpView showText:[NSString stringWithFormat:@"TTS Completed, error=%d",error]];
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
            
            [_popUpView showText:[NSString stringWithFormat:@"PROGRESS:%d",percent]];
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

- (void)dealloc
{
    [_aiuiAgent destroy];
    NSLog(@"dealloc");
}

- (void)onKeyBoardDown:(id) sender
{
    [_textView resignFirstResponder];
}


- (void)startTTSTest{
    if (_aiuiAgent == nil)
    {
        [_popUpView showText:NSLocalizedString(@"agentNull", nil)];
        return;
    }
    NSData *textData = [self.textView.text dataUsingEncoding:NSUTF8StringEncoding];
    NSString *params = [NSString stringWithFormat:@"vcn=x_chongchong,engine_type=xtts,speed=50,pitch=50,volume=50"];
    
    IFlyAIUIMessage *msg = [[IFlyAIUIMessage alloc] init];
    msg.msgType = CMD_TTS;
    msg.arg1 = TTS_START;
    msg.params = params;
    msg.data = textData;
    
    [_aiuiAgent sendMessage:msg];
    
    
    [NSTimer scheduledTimerWithTimeInterval:8
                                     target:self
                                   selector:@selector(pauseTTSTest)
                                   userInfo:nil
                                    repeats:false];
    
}

- (void)pauseTTSTest{
    if (_aiuiAgent == nil)
    {
        [_popUpView showText:NSLocalizedString(@"agentNull", nil)];
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
        [_popUpView showText:NSLocalizedString(@"agentNull", nil)];
        return;
    }
    IFlyAIUIMessage *msg = [[IFlyAIUIMessage alloc] init];
    msg.msgType = CMD_TTS;
    msg.arg1 = TTS_RESUME;
    
    [_aiuiAgent sendMessage:msg];
    
    [NSTimer scheduledTimerWithTimeInterval:10
                                     target:self
                                   selector:@selector(startTTSTest)
                                   userInfo:nil
                                    repeats:false];
}

#pragma mark - IFlyAIUIListener

- (void) onEvent:(IFlyAIUIEvent *) event {
    switch (event.eventType) {
            
        case EVENT_CONNECTED_TO_SERVER:
        {
            [_popUpView showText:@"CONNECT TO SERVER"];
            NSLog(@"CONNECT TO SERVER");
        } break;
            
        case EVENT_SERVER_DISCONNECTED:
        {
            [_popUpView showText:@"DISCONNECT TO SERVER"];
            NSLog(@"DISCONNECT TO SERVER");
        } break;
            
        case EVENT_STATE:
        {
            switch (event.arg1)
            {
                case STATE_IDLE:
                {
                    [_popUpView showText:@"EVENT_STATE: IDLE"];
                    NSLog(@"EVENT_STATE: %s", "IDLE");
                } break;
                    
                case STATE_READY:
                {
                    [_popUpView showText:@"EVENT_STATE: READY"];
                    NSLog(@"EVENT_STATE: %s", "READY");
                } break;
                    
                case STATE_WORKING:
                {
                    [_popUpView showText:@"EVENT_STATE: WORKING"];
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
                    [_popUpView showText:@"VAD_BOS"];
                    NSLog(@"EVENT_VAD_BOS");
                } break;
                    
                case VAD_EOS:
                {
                    [_popUpView showText:@"VAD_EOS"];
                    NSLog(@"EVENT_VAD_EOS");
                } break;
                    
                case VAD_VOL:
                {
                    NSString *volume = [[NSString alloc] initWithFormat:@"Volume:%d",event.arg2];
                    [_popUpView showText:volume];
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
            [_popUpView showText:error];
            NSLog(@"EVENT_ERROR: %@",error);
        } break;
    }
    
}

@end
