//
//  SSChatKeyBordFunctionView.m
//  SSChatView
//
//  Created by soldoros on 2018/9/25.
//  Copyright © 2018年 soldoros. All rights reserved.
//

#import "CustomVoiceView.h"
#import "SSOtherDefine.h"
#import "YYKit.h"
#import <AVFoundation/AVFoundation.h>
#import "YSCVoiceWaveView.h"
#import "YSCVoiceLoadingCircleView.h"
#import "CustomVoiceSleepingView.h"
#import "CustomVoiceLoadingView.h"

#import "CustomVoiceWaveView.h"

#define PQ_RADIANS(number)  ((M_PI * number)/ 180)
#define kRadius 40
#define kDefaultText @"weather"

@interface CustomVoiceView ()

@property (nonatomic, strong) UIView *containerView;

@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) YSCVoiceWaveView *voiceWaveView;
@property (nonatomic, strong) UIView *voiceWaveParentView;

@property (nonatomic, strong) CustomVoiceWaveView *voiceWaveViewNew;
@property (nonatomic,strong) UIView *voiceWaveParentViewNew;

@property (nonatomic, strong) CustomVoiceLoadingView *loadingView;
@property (nonatomic, strong) CustomVoiceSleepingView *sleepingView;
@property (nonatomic, strong) NSTimer *updateVolumeTimer;
@property (nonatomic, strong) UIButton *voiceWaveShowButton;
@property (nonatomic, strong) UIImageView *voiceIcon;
@property (nonatomic, strong) CAShapeLayer *voiceIconShapeLayer;
@property (nonatomic, strong) UIView *voiceIconContainer;
@property (nonatomic, strong) UIImageView *voiceIconRotatingView;
@property (nonatomic, strong) AVPlayer *voicePlayer;

// AIUI
@property (nonatomic, strong, readwrite) NSString *nlpResultText;
@property (nonatomic, strong, readwrite) NSString *iatResultText;
@property (nonatomic, strong, readwrite) NSString *commandResultText;

@property (nonatomic, strong, readwrite) NSString *nlpAnswerText;
@property (nonatomic, strong, readwrite) NSString *iatAnswerText;

@end

@implementation CustomVoiceView{
    BOOL _resetStatus;
    NSInteger _status;
}

- (void)dealloc {
    [self invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)invalidate {
    [_updateVolumeTimer invalidate];
    _updateVolumeTimer = nil;
    [_recorder stop];
    _recorder = nil;
    [self stopAutoTTS];
    [self stopRecord];
    [_aiuiAgent destroy];
    [_voiceWaveView removeFromParent];
    [_voiceWaveViewNew removeFromParent];
    [_loadingView stopLoading];
    _voiceWaveView = nil;
    _voiceWaveViewNew = nil;
}

-(instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        _status = 0;
        [self initUI];
    }
    return self;
    
}

- (void)initUI {

    self.backgroundColor = SSChatCellColor;
    self.userInteractionEnabled = YES;
    
    [self addSubview:self.containerView];
    
    [self setupRecorder];
    
    self.containerView.backgroundColor = [UIColor whiteColor];
    
    [self.containerView insertSubview:self.voiceWaveParentView atIndex:0];
    /*
    [self.voiceWaveView showInParentView:self.voiceWaveParentView];
    [self.voiceWaveView startVoiceWave];
    [self.voiceWaveView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:UIImageView.class]) {
            obj.userInteractionEnabled = YES;
        }
    }];
    */
    
    [self.containerView insertSubview:self.voiceWaveParentViewNew atIndex:1];
    
    [self.containerView addSubview:self.voiceWaveShowButton];
    
    [self.sleepingView startLoadingInParentView:self.voiceWaveParentView];
    
    // 启动 AIUI
    [self setupAIUI];
    
    [[NSRunLoop currentRunLoop] addTimer:self.updateVolumeTimer forMode:NSDefaultRunLoopMode];
}

- (void)setupAIUI {
    
    _autoTTS = true;
    
    self.nlpResultText = NSLocalizedString(kDefaultText, nil);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification object:nil];
    
    _globalSid = @"";
    
    _mLocationRequest = [[IFlyAIUILocationRequest alloc] init];
    [_mLocationRequest locationAsynRequest];
    
    [self onCreateClick:nil];
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)setNlpResultText:(NSString *)nlpResultText {
    NSLog(@"setNlpResultText:%@", nlpResultText);
    _nlpResultText = nlpResultText;
}

- (void)setIatResultText:(NSString *)iatResultText {
    NSLog(@"setIatResultText:%@", iatResultText);
    _iatResultText = iatResultText;
}

- (void)setNlpAnswerText:(NSString *)nlpAnswerText {
    NSLog(@"setNlpAnswerText:%@", nlpAnswerText);
    _nlpAnswerText = nlpAnswerText;
    if (self.onNlpAnswerText) {
        self.onNlpAnswerText(_nlpAnswerText);
    }
}

- (void)setIatAnswerText:(NSString *)iatAnswerText {
    NSLog(@"setIatAnswerText:%@", iatAnswerText);
    _iatAnswerText = iatAnswerText;
    if (self.onIatAnswerText) {
        self.onIatAnswerText(_iatAnswerText);
    }
}

// 不知为什么 voiceWaveShowButtonTouched 触发不了，可能是 RunLoop 的问题？
// 无奈之下这里用 touchesBegan 来监测点击事件。。
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self];
//    for (UIButton *button in self.buttonsOutletCollection)
//    {
//        if ([button.layer.presentationLayer hitTest:touchLocation])
//        {
//            // This button was hit whilst moving - do something with it here
//            break;
//        }
//    }
    if ([self.voiceWaveShowButton.layer.presentationLayer hitTest:touchLocation])
    {
        [self voiceWaveShowButtonTouched:self.voiceWaveShowButton];
    }
}

- (UIView *)containerView {
    if (_containerView == nil) {
        _containerView = [[UIView alloc] initWithFrame:self.bounds];
        _containerView.backgroundColor = UIColor.greenColor;
        _containerView.userInteractionEnabled = YES;
    }
    return _containerView;
}

- (void)updateVolume:(NSTimer *)timer
{
    // 音量由 recorder 提供
    [self.recorder updateMeters];
    CGFloat normalizedValue = pow (10, [self.recorder averagePowerForChannel:0] / 20);
    /*
    // 音量由AIUI回调，这里仅模拟一点点“噪声”
    int x = arc4random() % 9;
    //int y = (arc4random() % 10) + 10;
    int y = 0;
    NSString *str = [NSString stringWithFormat:@"%d.0%d",y,x];
    CGFloat f = [str floatValue];
    CGFloat normalizedValue = f;
    */
    [_voiceWaveViewNew changeVolume:normalizedValue];
}

-(void)setupRecorder
{
    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
    NSDictionary *settings = @{AVSampleRateKey:          [NSNumber numberWithFloat: 44100.0],
                               AVFormatIDKey:            [NSNumber numberWithInt: kAudioFormatAppleLossless],
                               AVNumberOfChannelsKey:    [NSNumber numberWithInt: 2],
                               AVEncoderAudioQualityKey: [NSNumber numberWithInt: AVAudioQualityMin]};
    
    NSError *error;
    self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    if(error) {
        NSLog(@"Ups, could not create recorder %@", error);
        return;
    }
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (error) {
        NSLog(@"Error setting category: %@", [error description]);
    }
    [self.recorder prepareToRecord];
    [self.recorder setMeteringEnabled:YES];
    [self.recorder record];
}

- (void)playVoice:(NSString *)fileName {
    // 创建播放器
    // 取MP3文件路径
    NSURL *url = [[NSBundle mainBundle] URLForResource:fileName withExtension:nil];
    // 创建播放器
    AVPlayer *player = [[AVPlayer alloc] init];
    // 播放的音乐
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:url];
    // 传入播放器
    player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    // 创建播放器
    //AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.voicePlayer = player;
    // 播放
    [self.voicePlayer play];
}

- (void)resetStatus {
    _resetStatus = YES;
    // 停止录音
    [self stopRecordBtnHandler:nil];
    [self updateStatus:0];
}

- (void)forceResetStatus {
    _resetStatus = YES;
    // 停止录音
    [self stopRecordBtnHandler:nil];
    // 移除，重新添加
    self.containerView.frame = self.bounds;
    self.voiceWaveParentView.frame = self.containerView.bounds;
    self.voiceWaveParentViewNew.frame = self.containerView.bounds;
    [self.sleepingView removeFromSuperview];
    [self.loadingView removeFromSuperview];
    [self.voiceWaveShowButton removeFromSuperview];
    [self.voiceIcon removeFromSuperview];
    self.voiceIcon = nil;
    self.voiceWaveShowButton = nil;
    self.loadingView = nil;
    self.sleepingView = nil;
    
    [self.containerView addSubview:self.voiceWaveShowButton];
    
    // 更新
    [self forceUpdateStatus:0];
}

- (void)voiceWaveShowButtonTouched:(UIButton *)sender
{
    [self updateStatus:_status+1];
}

- (void)forceUpdateStatus:(NSInteger)status {
    if (_status % 3 == 2 && status % 3 == 0) { // 识别中状态 --> 休眠状态
        if (!_resetStatus) {
            [self playVoice:@"stop.mp3"];
        }
    }
    if (_status % 3 == 0 && status % 3 == 1) { // 休眠状态 --> 录音状态
        if (!_resetStatus) {
            [self playVoice:@"start.mp3"];
        }
    }
    if (_status % 3 == 1) { // 录音状态 --> 其他状态
        [self.voiceWaveViewNew stopVoiceWaveWithShowLoadingViewCallback:^{
            // 先停掉所有的
            [self stopAll];
            _status = status;
            [self updateCurrentStatus];
        }];
    } else {
        // 先停掉所有的
        [self stopAll];
        _status = status;
        [self updateCurrentStatus];
    }
}

- (void)updateStatus:(NSInteger)status {
    if (_status % 3 == status % 3) return;
    [self forceUpdateStatus:status];
}

- (void)stopAll {
    [self stopRecordBtnHandler:nil];
    [self.recorder stop];
    [self.sleepingView stopLoading];
    [self.loadingView stopLoading];
    [self.updateVolumeTimer invalidate];
    _updateVolumeTimer = nil;
    [self stopCirlAnimationTo:self.voiceIconRotatingView];
}

- (void)updateCurrentStatus {
    if (_status % 3 == 0) { // 休眠状态
        [self.sleepingView startLoadingInParentView:self.containerView];
    } else if (_status % 3 == 1) { // 录音状态
        [self.voiceWaveViewNew showInParentView:self.voiceWaveParentViewNew];
        [self.voiceWaveViewNew startVoiceWave];
        [self addCirlAnimationTo:self.voiceIconRotatingView];
        [self.recorder record]; // 开始录音
        // 开始录音
        [self _startRecordBtnHandler:nil];
        [[NSRunLoop currentRunLoop] addTimer:self.updateVolumeTimer forMode:NSRunLoopCommonModes];
    } else { // 识别中状态
        [self.loadingView startLoadingInParentView:self.containerView];
    }
    _resetStatus = NO;
}

#pragma mark - getters

- (YSCVoiceWaveView *)voiceWaveView
{
    if (!_voiceWaveView) {
        _voiceWaveView = [[YSCVoiceWaveView alloc] init];
        _voiceWaveView.userInteractionEnabled = YES;
    }
    
    return _voiceWaveView;
}

- (UIView *)voiceWaveParentView
{
    if (!_voiceWaveParentView) {
        _voiceWaveParentView = [[UIView alloc] init];
        _voiceWaveParentView.userInteractionEnabled = YES;
        //CGSize screenSize = [UIScreen mainScreen].bounds.size;
        //_voiceWaveParentView.frame = CGRectMake(0, 0, screenSize.width, 320);
        _voiceWaveParentView.frame = self.containerView.bounds;
//        _voiceWaveParentView.center = CGPointMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0);
    }
    
    return _voiceWaveParentView;
}

- (CustomVoiceWaveView *)voiceWaveViewNew
{
    if (!_voiceWaveViewNew) {
        self.voiceWaveViewNew = [[CustomVoiceWaveView alloc] init];
        [_voiceWaveViewNew setVoiceWaveNumber:6];
    }
    
    return _voiceWaveViewNew;
}

- (UIView *)voiceWaveParentViewNew
{
    if (!_voiceWaveParentViewNew) {
        _voiceWaveParentViewNew = [[UIView alloc] init];
        //CGSize screenSize = [UIScreen mainScreen].bounds.size;
        //_voiceWaveParentViewNew.frame = CGRectMake(0, 330, screenSize.width, 320);
        _voiceWaveParentViewNew.frame = self.containerView.bounds;
//        _voiceWaveParentViewNew.center = CGPointMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0);
    }
    
    return _voiceWaveParentViewNew;
}

- (CustomVoiceLoadingView *)loadingView
{
    if (!_loadingView) {
        //CGSize screenSize = [UIScreen mainScreen].bounds.size;
        //CGPoint loadViewCenter = CGPointMake(screenSize.width / 2.0, 160);
        CGPoint loadViewCenter = self.containerView.center;
        self.loadingView = [[CustomVoiceLoadingView alloc] initWithCircleRadius:kRadius center:loadViewCenter];
    }
    
    return _loadingView;
}

- (CustomVoiceSleepingView *)sleepingView
{
    if (!_sleepingView) {
        //CGSize screenSize = [UIScreen mainScreen].bounds.size;
        //CGPoint loadViewCenter = CGPointMake(screenSize.width / 2.0, 160);
        CGPoint loadViewCenter = self.containerView.center;
        self.sleepingView = [[CustomVoiceSleepingView alloc] initWithCircleRadius:kRadius center:loadViewCenter];
    }
    
    return _sleepingView;
}

- (UIButton *)voiceWaveShowButton
{
    if (!_voiceWaveShowButton) {
        CGFloat buttonHeight = 100;
        _voiceWaveShowButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonHeight, buttonHeight)];
        _voiceWaveShowButton.userInteractionEnabled = YES;
        _voiceWaveShowButton.center = self.containerView.center;
        [_voiceWaveShowButton addTarget:self action:@selector(voiceWaveShowButtonTouched:) forControlEvents:UIControlEventTouchDown];
        //中间麦克风图
        UIImageView *imgMicrophone = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 48)];
        //imgMicrophone.center = CGPointMake(30, 30);
        imgMicrophone.center = CGPointMake(buttonHeight/2, buttonHeight/2-1); // 不知道为啥偏下了一点。。
        imgMicrophone.contentMode = UIViewContentModeCenter;
        imgMicrophone.image = [UIImage imageNamed:@"microphone"];
        //[_voiceWaveShowButton setImage:[UIImage imageNamed:@"microphone"] forState:UIControlStateNormal];
        [_voiceWaveShowButton addSubview:imgMicrophone];
        
        imgMicrophone.clipsToBounds = YES;
        
        CGRect voiceImageViewRect = imgMicrophone.bounds;
        UIView *voiceIconContainer = [[UIView alloc] init];
        // 全部旋转
        voiceIconContainer.frame = voiceImageViewRect;
        self.voiceIcon.frame = voiceImageViewRect;
        /*
        // 右半部旋转
        voiceIconContainer.frame = CGRectMake(voiceImageViewRect.size.width/2, 0, voiceImageViewRect.size.width/2, voiceImageViewRect.size.height);
        // 左半部漏出
        //self.voiceIcon.frame = CGRectMake(0, 0, voiceImageViewRect.size.width, voiceImageViewRect.size.height);
        // 右半部漏出
        self.voiceIcon.frame = CGRectMake(-voiceImageViewRect.size.width/2, 0, voiceImageViewRect.size.width, voiceImageViewRect.size.height);
        voiceIconContainer.backgroundColor = UIColor.clearColor;
        */
        voiceIconContainer.clipsToBounds = YES;
        [voiceIconContainer addSubview:self.voiceIcon];
        _voiceIconContainer = [UIView new];
        _voiceIconContainer.frame = voiceImageViewRect;
        _voiceIconContainer.backgroundColor = UIColor.clearColor;
        [_voiceIconContainer addSubview:voiceIconContainer];
        [imgMicrophone addSubview:_voiceIconContainer];
        // 代码绘制话筒，放弃。。
        //self.voiceIconShapeLayer = [self generateVoiceIconShapeLayer];
        //self.voiceIcon.layer.mask = _voiceIconShapeLayer;
        
        /*
        // 切图方案
        // 镂空切图
        UIImageView *imgMicrophone2 = [[UIImageView alloc] init];
        imgMicrophone2.frame = CGRectMake(0, 0, voiceImageViewRect.size.width, voiceImageViewRect.size.height);
        imgMicrophone2.contentMode = UIViewContentModeScaleAspectFill;
        imgMicrophone2.image = [UIImage imageNamed:@"microphone_mask.jpg"];
        [imgMicrophone addSubview:imgMicrophone2];
        // 在适当时机调用 [self addCirlAnimationTo:self.voiceIconContainer];
        */
        
        // 蒙版镂空方案
        UIImageView *imgMicrophone3 = [[UIImageView alloc] init];
        imgMicrophone3.frame = CGRectMake(0, 0, voiceImageViewRect.size.width, voiceImageViewRect.size.height);
        imgMicrophone3.contentMode = UIViewContentModeScaleAspectFill;
        imgMicrophone3.image = [UIImage imageNamed:@"microphone_background.jpg"];
        UIImageView *imgMicrophone4 = [[UIImageView alloc] init];
        imgMicrophone4.frame = imgMicrophone3.bounds;
        imgMicrophone4.contentMode = UIViewContentModeCenter;
        imgMicrophone4.image = [UIImage imageNamed:@"microphone"];
        
        self.voiceIconRotatingView = imgMicrophone3;
        self.voiceIcon.layer.mask = imgMicrophone4.layer;
        [self.voiceIcon addSubview:imgMicrophone3];
        // 在适当时机调用 [self addCirlAnimationTo:self.voiceIconRotatingView];
        
    }
    
    return _voiceWaveShowButton;
}

- (UIImageView *)voiceIcon
{
    if (!_voiceIcon) {
        _voiceIcon = [[UIImageView alloc] init];
        _voiceIcon.userInteractionEnabled = YES;
        _voiceIcon.image = [UIImage imageNamed:@"microphone_background.jpg"];
        _voiceIcon.layer.masksToBounds = YES;
        /*
         mask不是遮罩，不是add到layer上的另一个layer，而是控制layer本身渲染的一个layer。
         效果是：比如imageLayer有一个maskLayer作为mask（注意maskLayer可以不跟imageLayer大小一样），
         那maskLayer透明的地方，imageLayer就不会渲染，而是变透明，显示出imageLayer之后的内容，
         maskLayer不透明的地方，imageLayer就会正常渲染，显示出imageLayer本来的内容
         如果maskLayer比imageLayer要小，那默认的maskLayer之外的地方都是透明的，都不会渲染。
         
         注意：作为mask的layer不能有superLayer或者subLayer！
         
         作者：千年积木
         链接：https://www.jianshu.com/p/08a1f830a2ca
         来源：简书
         著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。
         */
    }
    
    return _voiceIcon;
}

#pragma mark - animation

- (void)addCirlAnimationTo:(UIView *)view
{
    CAKeyframeAnimation *backgroundTransform = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    backgroundTransform.values = @[[NSValue valueWithCATransform3D:CATransform3DIdentity],[NSValue valueWithCATransform3D:CATransform3DMakeRotation(0.5*M_PI, 0, 0, 1)], [NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI, 0, 0, 1)], [NSValue valueWithCATransform3D:CATransform3DMakeRotation(1.5*M_PI, 0, 0, 1)],[NSValue valueWithCATransform3D:CATransform3DMakeRotation(2*M_PI, 0, 0, 1)]];
    backgroundTransform.duration = 1.0;
    backgroundTransform.repeatCount = INFINITY;
    backgroundTransform.calculationMode = kCAAnimationLinear;
//    backgroundTransform.beginTime = CACurrentMediaTime();
    
    [view.layer addAnimation:backgroundTransform forKey:nil];
}

- (void)stopCirlAnimationTo:(UIView *)view
{
    [view.layer removeAllAnimations];
}

- (NSTimer *)updateVolumeTimer
{
    if (!_updateVolumeTimer) {
        //self.updateVolumeTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(updateVolume:) userInfo:nil repeats:YES];
        self.updateVolumeTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(updateVolume:) userInfo:nil repeats:YES];
    }
    
    return _updateVolumeTimer;
}

#pragma mark - AIUI


- (void)sendTextToAIUI:(NSString *)text
{
    if (_aiuiAgent == nil)
    {
        NSLog(NSLocalizedString(@"agentNull", nil));
        return;
    }

    if (self.aiuiState == STATE_READY) {
        IFlyAIUIMessage *msg = [[IFlyAIUIMessage alloc] init];
        msg.msgType = CMD_WAKEUP;
        [_aiuiAgent sendMessage:msg];
    }
    
    NSData *textData = [text dataUsingEncoding:NSUTF8StringEncoding];

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
        NSLog(NSLocalizedString(@"agentNull", nil));
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
        NSLog(NSLocalizedString(@"agentNull", nil));
        return;
    }
    NSString *params;
    
    if (!_autoTTS) {
        //由sdk内部进行合成
        params = @"{\"tts\":{\"play_mode\":\"sdk\"}}";
        _autoTTS = YES;
    } else {
        //sdk不自动合成，抛出EVENT_RESULT事件包含音频数据开发者自己处理
        params = @"{\"tts\":{\"play_mode\":\"user\"}}";
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
        NSLog(NSLocalizedString(@"agentNull", nil));
        return;
    }
    if (!_globalSid && [_globalSid length] == 0)
    {
        NSLog(NSLocalizedString(@"syncNotYet", nil));
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
        NSLog(NSLocalizedString(@"agentNull", nil));
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
        NSLog(NSLocalizedString(@"agentNull", nil));
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
        NSLog(NSLocalizedString(@"agentNull", nil));
        return;
    }
    //[_startRecordBtn setEnabled:YES];
    
    [self stopRecord];
}


/* 销毁Agent */
- (IBAction)onDestroyClick:(id)sender {
    self.nlpResultText = NSLocalizedString(kDefaultText, nil);
    self.iatResultText = @"";
    
    [self stopRecord];
    [_aiuiAgent destroy];

}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    self.nlpResultText = NSLocalizedString(kDefaultText, nil);
    
    [self stopRecord];
}

#pragma mark - private

//停止录音
- (void)stopRecord{
    IFlyAIUIMessage *msg = [[IFlyAIUIMessage alloc] init];
    msg.msgType = CMD_STOP_RECORD;
    [_aiuiAgent sendMessage:msg];
}

//处理结果
- (void)processResult:(IFlyAIUIEvent *)event{
    
    NSString *info = event.info;
    NSLog(@"info = %@", info);
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
            if (rltStr.length > 0)
            {
                self.nlpResultText = rltStr;
                NSData *data = [rltStr dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *rstDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                NSString *answer = rstDic[@"intent"][@"answer"][@"text"];
                NSLog(@"answer is %@", rstDic[@"intent"][@"answer"][@"text"]);
                self.nlpAnswerText = answer;
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
    } else if([sub isEqualToString:@"iat"]){
        
        NSString *cnt_id = [content objectForKey:@"cnt_id"];
        if(!cnt_id){
            NSLog(@"Content Id is empty");
            return;
        }
        
        NSData *rltData = [event.data objectForKey:cnt_id];
        if(rltData){
            NSString *rltStr = [[[NSString alloc]initWithData:rltData encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\0" withString:@""];
            NSLog(@"iat result: %@", rltStr);
            if (rltStr.length > 0)
            {
                self.iatResultText = rltStr;
                NSData *data = [rltStr dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *rstDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                NSLog(@"iat result dict: %@", rstDic);
                NSArray *words = rstDic[@"text"][@"ws"];
                NSString *answer = @"";
                for (NSDictionary *dict in words) {
                    NSArray *cw = dict[@"cw"];
                    for (NSDictionary *w in cw) {
                        NSString *word = w[@"w"];
                        answer = [answer stringByAppendingString:word];
                    }
                }
                self.iatAnswerText = answer;
            }
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
                    self.commandResultText = NSLocalizedString(@"syncSuccess", nil);
                    
                }
                else
                {
                    NSString *retCode = [[NSString alloc] initWithFormat:@"retcode:%d",retcode];
                    NSLog(@"retCode:%@", retCode);
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
            
            self.commandResultText = rltInfo;
        }
    }
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
        
        case EVENT_START_RECORD:
        {
            NSLog(@"EVENT_START_RECORD");
        } break;
            
        case EVENT_STOP_RECORD:
        {
            NSLog(@"EVENT_STOP_RECORD");
            [self updateStatus:2]; // 录音状态 --> 识别中状态
        } break;
            
        case EVENT_STATE:
        {
            switch (event.arg1)
            {
                case STATE_IDLE:
                {
                    self.aiuiState = STATE_IDLE;
                    NSLog(@"EVENT_STATE: %s", "IDLE");
                } break;
                    
                case STATE_READY:
                {
                    self.aiuiState = STATE_READY;
                    NSLog(@"EVENT_STATE: %s", "READY");
                } break;
                    
                case STATE_WORKING:
                {
                    self.aiuiState = STATE_WORKING;
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
                    //NSString *volume = [[NSString alloc] initWithFormat:@"Volume:%d",event.arg2];
                    NSLog(@"vol: %d", event.arg2);
                    //CGFloat normalizedValue = pow (10, event.arg2 / 20);
                    //[_voiceWaveViewNew changeVolume:normalizedValue];
                } break;
            }
        } break;
            
        case EVENT_RESULT:
        {
            NSLog(@"EVENT_RESULT");
            if (_status % 3 == 2) { // 当前状态如果是识别中状态
                [self updateStatus:0]; // 识别中状态 --> 休眠状态
            }
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
            NSLog(@"EVENT_ERROR: %@",error);
        } break;
    }
    
}

@end
