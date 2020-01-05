/*
 * UnderstandViewController.m
 * AIUIDemo
 *
 *  Created on: 2018年1月1日
 *      Author: 讯飞AIUI开放平台（http://aiui.xfyun.cn）
 */

#import <QuartzCore/QuartzCore.h>
#import "UnderstandViewController.h"


@implementation UnderstandViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"viewDidLoad");
    _autoTTS = true;
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    _textView.layer.borderWidth = 0.5f;
    _textView.layer.borderColor = [[UIColor whiteColor] CGColor];
    [_textView.layer setCornerRadius:7.0f];
    
    _defaultText = NSLocalizedString(@"weather", nil);
    _textView.text = [NSString stringWithFormat:@"%@",self.defaultText];
    
    UIBarButtonItem *spaceBtnItem= [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem * hideBtnItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"hide", @"Hide") style:UIBarButtonItemStylePlain target:self action:@selector(onKeyBoardDown:)];
    [hideBtnItem setTintColor:[UIColor whiteColor]];
    
    UIToolbar * toolbar = [[ UIToolbar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    toolbar.barStyle = UIBarStyleBlackTranslucent;
    NSArray * array = [NSArray arrayWithObjects:spaceBtnItem,hideBtnItem, nil];
    [toolbar setItems:array];
    _textView.inputAccessoryView = toolbar;
    CGFloat posY = self.textView.frame.origin.y+self.textView.frame.size.height/6;
    _popUpView = [[PopupView alloc] initWithFrame:CGRectMake(100, posY, 0, 0) withParentView:self.view];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification object:nil];
    
    _globalSid = @"";
    
    _mLocationRequest = [[IFlyAIUILocationRequest alloc] init];
    [_mLocationRequest locationAsynRequest];
}

- (void)viewDidUnload
{
    NSLog(@"%s,viewDidUnload",__func__);
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    
    [_startRecordBtn setEnabled:YES];
    
    [_stopRecordBtn setEnabled:YES];
    
    [super viewWillAppear:animated];
    
    NSLog(@"viewWillAppear");
}

- (void)viewWillDisappear:(BOOL)animated
{
    
    [self stopAutoTTS];
    [self stopRecord];
    
   [super viewWillDisappear:animated];
    
    NSLog(@"viewWillDisappear");
}


- (void)dealloc
{
    [self stopRecord];
    [_aiuiAgent destroy];
    NSLog(@"%s,dealloc",__func__);
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)onTextBtnHandler:(id)sender
{
    if (_aiuiAgent == nil)
    {
        [_popUpView showText:NSLocalizedString(@"agentNull", nil)];
        return;
    }
    
    _textView.text = NSLocalizedString(@"weather", nil);

    if (self.aiuiState == STATE_READY) {
        IFlyAIUIMessage *msg = [[IFlyAIUIMessage alloc] init];
        msg.msgType = CMD_WAKEUP;
        [_aiuiAgent sendMessage:msg];
    }
    
    NSData *textData = [_textView.text dataUsingEncoding:NSUTF8StringEncoding];

    IFlyAIUIMessage *msg = [[IFlyAIUIMessage alloc] init];
    msg.msgType = CMD_WRITE;
    msg.params = @"data_type=text,tag=123";
    msg.data = textData;

    [_aiuiAgent sendMessage:msg];
    
}

/* 创建Agent */

- (IBAction)onCreateClick:(id)sender
{
    // 读取aiui.cfg配置文件
    NSString *cfgFilePath = [[NSBundle mainBundle] pathForResource:@"aiui" ofType:@"cfg"];
    NSString *cfg = [NSString stringWithContentsOfFile:cfgFilePath encoding:NSUTF8StringEncoding error:nil];
    
    //创建AIUIAgent
    _aiuiAgent = [IFlyAIUIAgent createAgent:cfg withListener:self];
    
    //发送唤醒消息
    IFlyAIUIMessage *wakeuMsg = [[IFlyAIUIMessage alloc]init];
    wakeuMsg.msgType = CMD_WAKEUP;
    [_aiuiAgent sendMessage:wakeuMsg];
    
}

/* 上传联系人 */

- (IBAction)onUpContactsClick:(id)sender
{
    if (_aiuiAgent == nil)
    {
        [_popUpView showText:NSLocalizedString(@"agentNull", nil)];
        return;
    }
    /* 联系人（如下）信息的base64编码
     *{"name":"刘德华", "phoneNumber":"13512345671"}
     *{"name":"张学友", "phoneNumber":"13512345672"}
     *{"name":"张右兵", "phoneNumber":"13512345673"}
     *{"name":"吴秀波", "phoneNumber":"13512345674"}
     *{"name":"黎晓明", "phoneNumber":"13512345675"}
     */
    NSString *contactsData = [NSString stringWithFormat:@"eyJuYW1lIjoi5YiY5b635Y2OIiwgInBob25lTnVtYmVyIjoiMTM1MTIzNDU2NzEifQp7Im5hbWUiOiLlvKDlrablj4siLCAicGhvbmVOdW1iZXIiOiIxMzUxMjM0NTY3MiJ9CnsibmFtZSI6IuW8oOWPs+WFtSIsICJwaG9uZU51bWJlciI6IjEzNTEyMzQ1NjczIn0KeyJuYW1lIjoi5ZC056eA5rOiIiwgInBob25lTnVtYmVyIjoiMTM1MTIzNDU2NzQifQp7Im5hbWUiOiLpu47mmZMiLCAicGhvbmVOdW1iZXIiOiIxMzUxMjM0NTY3NSJ9"];
    
    NSMutableDictionary *dataDic = [NSMutableDictionary dictionary];
    NSMutableDictionary *paramDic = [NSMutableDictionary dictionary];
    
    [paramDic setObject:@"uid" forKey:@"id_name"];
    [paramDic setObject:@"IFLYTEK.telephone_contact" forKey:@"res_name"];
    
    [dataDic setObject:paramDic forKey:@"param"];
    [dataDic setObject:contactsData forKey:@"data"];
    
    NSError *err;
    NSData *data1 = [NSJSONSerialization dataWithJSONObject:dataDic options:NSJSONWritingPrettyPrinted error:&err];
    if(!data1){
        NSLog(@"parse error! dataDic=%@", dataDic);
        return;
    }
    
    NSString *paramStr = [[NSString alloc]initWithData:data1 encoding:NSUTF8StringEncoding];
    
    //同步个性化数据
    IFlyAIUIMessage *msg1 = [[IFlyAIUIMessage alloc] init];
    msg1.msgType = CMD_SYNC;
    msg1.arg1 = SYNC_DATA_SCHEMA;
    msg1.params = paramStr;
    msg1.data = data1;
    
    [_aiuiAgent sendMessage:msg1];
    
    NSMutableDictionary *dataParamJson = [NSMutableDictionary dictionary];
    NSMutableDictionary *persParamJson = [NSMutableDictionary dictionary];
    
    [persParamJson setObject:@"{\"uid\":\"\"}" forKey:@"pers_param"];
    [dataParamJson setObject:persParamJson forKey:@"audioparams"];
    
    NSData *data2 = [NSJSONSerialization dataWithJSONObject:dataParamJson options:NSJSONWritingPrettyPrinted error:&err];
    if(!data2){
        NSLog(@"parse error! dataParamJson=%@", dataParamJson);
        return;
    }
    
    NSString *persDataStr = [[NSString alloc]initWithData:data2 encoding:NSUTF8StringEncoding];
    
    //生效使用
    IFlyAIUIMessage *msg2 = [[IFlyAIUIMessage alloc] init];
    msg2.msgType = CMD_SET_PARAMS;
    msg2.params = persDataStr;
    
    [_aiuiAgent sendMessage:msg2];
    
}

- (IBAction)onAutoTTSClick:(id)sender
{
    if (_aiuiAgent == nil)
    {
        [_popUpView showText:NSLocalizedString(@"agentNull", nil)];
        return;
    }
    NSString *params;
    
    if (!_autoTTS) {
        //由sdk内部进行合成
        params = @"{\"tts\":{\"play_mode\":\"sdk\"}}";
        [_autoTTSBtn setTitle: NSLocalizedString(@"NonAutoTTS", nil)forState:UIControlStateNormal];
        _autoTTS = YES;
    } else {
        //sdk不自动合成，抛出EVENT_RESULT事件包含音频数据开发者自己处理
        params = @"{\"tts\":{\"play_mode\":\"user\"}}";
        [_autoTTSBtn setTitle: NSLocalizedString(@"AutoTTS", nil)forState:UIControlStateNormal];
        _autoTTS = NO;
    }
    //设置参数
    IFlyAIUIMessage *msg = [[IFlyAIUIMessage alloc] init];
    msg.msgType = CMD_SET_PARAMS;
    msg.params = params;
    [_aiuiAgent sendMessage:msg];
}

/* 打包（上传联系人结果）查询 */

- (IBAction)onPackQueryClick:(id)sender
{
    if (_aiuiAgent == nil)
    {
        [_popUpView showText:NSLocalizedString(@"agentNull", nil)];
        return;
    }
    if (!_globalSid && [_globalSid length] == 0)
    {
        [_popUpView showText:NSLocalizedString(@"syncNotYet", nil)];
        return;
    }
    
    NSMutableDictionary *queryJson = [NSMutableDictionary dictionaryWithObjectsAndKeys:_globalSid, @"sid", nil];
    
    NSError *err;
    NSData *data = [NSJSONSerialization dataWithJSONObject:queryJson options:NSJSONWritingPrettyPrinted error:&err];
    if(!data){
        NSLog(@"parse error! queryJson=%@", queryJson);
        return;
    }
    
    NSString *dataStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    
    IFlyAIUIMessage *msg = [[IFlyAIUIMessage alloc] init];
    msg.msgType = CMD_QUERY_SYNC_STATUS;
    msg.arg1 = SYNC_DATA_SCHEMA;
    msg.params = dataStr;
    
    [_aiuiAgent sendMessage:msg];
}

/* 开始语音识别和语义理解 */

- (IBAction)_startRecordBtnHandler:(id)sender
{
    if (_aiuiAgent == nil)
    {
        [_popUpView showText:NSLocalizedString(@"agentNull", nil)];
        return;
    }
    if(_mLocationRequest)
    {
        CLLocation *location = [_mLocationRequest getLocation];
        if(location)
        {
            NSNumber *lng = nil;
            NSNumber *lat = nil;
            
            CLLocationCoordinate2D clm = [location coordinate];
            
            lng = [[NSNumber alloc] initWithDouble:round(clm.longitude * 100000000) / 100000000];
            lat = [[NSNumber alloc] initWithDouble:round(clm.latitude * 100000000) / 100000000];
            
            //可实时调用该接口更新GPS位置信息
            [_aiuiAgent setGPSwithLng:lng andLat:lat];
        }
    }
    
    if (self.aiuiState == STATE_IDLE) {
        [_popUpView showText:NSLocalizedString(@"agentNull", nil)];
        return;
    }
    if (self.aiuiState == STATE_READY) {
        IFlyAIUIMessage *msg = [[IFlyAIUIMessage alloc] init];
        msg.msgType = CMD_WAKEUP;
        [_aiuiAgent sendMessage:msg];
    }
    [self stopAutoTTS];
    
    IFlyAIUIMessage *msg = [[IFlyAIUIMessage alloc] init];
    msg.msgType = CMD_START_RECORD;
    
    [_aiuiAgent sendMessage:msg];
    
}

/* 停止语音识别和语义理解 */

- (IBAction)stopRecordBtnHandler:(id)sender
{
    if (_aiuiAgent == nil)
    {
        [_popUpView showText:NSLocalizedString(@"agentNull", nil)];
        return;
    }
    [_startRecordBtn setEnabled:YES];
    
    [self stopRecord];
}



- (void)onKeyBoardDown:(id) sender
{
    [_textView resignFirstResponder];
}


/* 销毁Agent */
- (IBAction)onDestroyClick:(id)sender {
    _textView.text = NSLocalizedString(@"weather", nil);
    
    [self stopRecord];
    [_aiuiAgent destroy];

}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    _textView.text = NSLocalizedString(@"weather", nil);
    
    [self stopRecord];
}

#pragma mark - private

//停止录音
- (void)stopRecord{
    IFlyAIUIMessage *msg = [[IFlyAIUIMessage alloc] init];
    msg.msgType = CMD_STOP_RECORD;
    [_aiuiAgent sendMessage:msg];
    
    [_textView resignFirstResponder];
}

//处理结果
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
    
    if([sub isEqualToString:@"nlp"]){
        
        NSString *cnt_id = [content objectForKey:@"cnt_id"];
        if(!cnt_id){
            NSLog(@"Content Id is empty");
            return;
        }
        
        NSData *rltData = [event.data objectForKey:cnt_id];
        if(rltData){
            NSString *rltStr = [[[NSString alloc]initWithData:rltData encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\0" withString:@""];
            NSLog(@"nlp result: %@", rltStr);
            if (rltStr.length > 20)
            {
                self.textView.text = rltStr;
                self.textView.layoutManager.allowsNonContiguousLayout = NO;
                NSData *data = [rltStr dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *rstDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                NSLog(@"answer is %@", rstDic[@"intent"][@"answer"][@"text"]);
            }
        }
    } else if([sub isEqualToString:@"tts"]){
        NSLog(@"receive tts event");
        
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

//取消合成
- (void)stopAutoTTS
{
    IFlyAIUIMessage *msg = [[IFlyAIUIMessage alloc] init];
    msg.msgType = CMD_TTS;
    msg.arg1 = TTS_CANCEL;
    [_aiuiAgent sendMessage:msg];
}

- (void)processCmdRtn:(IFlyAIUIEvent *)event{
    
    if(CMD_SYNC == event.arg1)
    {
        int retcode = event.arg2;
        int dtype;
        NSNumber *dtypeNum = [event.data objectForKey:@"sync_dtype"];
        if(!dtypeNum){
            dtype = -1;
        }else{
            dtype = [dtypeNum intValue];
        }
        
        switch (dtype)
        {
            case SYNC_DATA_SCHEMA:
            {
                NSString *syncSid = [event.data objectForKey:@"sid"];
                if(syncSid){
                    self.globalSid = syncSid;
                }else{
                    self.globalSid = @"";
                }
                
                if (0 == retcode)
                {
                    self.textView.text = NSLocalizedString(@"syncSuccess", nil);
                    self.textView.layoutManager.allowsNonContiguousLayout = NO;
                    
                }
                else
                {
                    NSString *retCode = [[NSString alloc] initWithFormat:@"retcode:%d",retcode];
                    [_popUpView showText:retCode];
                }
                NSLog(@"sid=%@",_globalSid);
            } break;
                
            case SYNC_DATA_QUERY:
            {
                if (0 == retcode)
                {
                    NSLog(@"sync query success");
                }
                else
                {
                    NSLog(@"sync query error= %d",retcode);
                }
            } break;
        }
    } else if(CMD_QUERY_SYNC_STATUS == event.arg1)
    {
        int syncType;
        NSNumber *syncTypeNum = [event.data objectForKey:@"sync_dtype"];
        if(syncTypeNum){
            syncType = [syncTypeNum intValue];
        }else{
            syncType = -1;
        }
        
        if (SYNC_DATA_QUERY == syncType)
        {
            NSString *rltInfo = [event.data objectForKey:@"result"];
            
            self.textView.text = rltInfo;
            self.textView.layoutManager.allowsNonContiguousLayout = NO;
        }
    }
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
        
        case EVENT_START_RECORD:
        {
            [_popUpView showText:@"EVENT_START_RECORD"];
            NSLog(@"EVENT_START_RECORD");
        } break;
            
        case EVENT_STOP_RECORD:
        {
            [_popUpView showText:@"EVENT_STOP_RECORD"];
            NSLog(@"EVENT_STOP_RECORD");
        } break;
            
        case EVENT_STATE:
        {
            switch (event.arg1)
            {
                case STATE_IDLE:
                {
                    self.aiuiState = STATE_IDLE;
                    [_popUpView showText:@"EVENT_STATE: IDLE"];
                    NSLog(@"EVENT_STATE: %s", "IDLE");
                } break;
                    
                case STATE_READY:
                {
                    self.aiuiState = STATE_READY;
                    [_popUpView showText:@"EVENT_STATE: READY"];
                    NSLog(@"EVENT_STATE: %s", "READY");
                } break;
                    
                case STATE_WORKING:
                {
                    self.aiuiState = STATE_WORKING;
                    [_popUpView showText:@"EVENT_STATE: WORKING"];
                    NSLog(@"EVENT_STATE: %s", "WORKING");
                } break;
            }
        } break;
            
        case EVENT_WAKEUP:
        {
            [_popUpView showText:@"EVENT_WAKEUP"];
            NSLog(@"EVENT_WAKEUP");
        } break;
            
        case EVENT_SLEEP:
        {
            [_popUpView showText:@"EVENT_SLEEP"];
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
                    
                    NSLog(@"vol: %d", event.arg2);
                } break;
            }
        } break;
            
        case EVENT_RESULT:
        {
            NSLog(@"EVENT_RESULT");
            [self processResult:event];
        } break;
            
        case EVENT_CMD_RETURN:
        {
            NSLog(@"EVENT_CMD_RETURN");
            [self processCmdRtn:event];
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

