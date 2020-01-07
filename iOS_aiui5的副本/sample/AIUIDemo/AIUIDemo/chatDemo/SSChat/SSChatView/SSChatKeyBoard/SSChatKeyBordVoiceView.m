//
//  SSChatKeyBordFunctionView.m
//  SSChatView
//
//  Created by soldoros on 2018/9/25.
//  Copyright © 2018年 soldoros. All rights reserved.
//

#import "SSChatKeyBordVoiceView.h"
#import "SSOtherDefine.h"
#import "YYKit.h"
#import <AVFoundation/AVFoundation.h>
#import "YSCVoiceWaveView.h"
#import "YSCVoiceLoadingCircleView.h"
#import "CustomVoiceSleepingView.h"
#import "CustomVoiceLoadingView.h"

#import "YSCNewVoiceWaveView.h"

#define PQ_RADIANS(number)  ((M_PI * number)/ 180)
#define kRadius 25

@interface SSChatKeyBordVoiceView ()

@property (nonatomic, strong) UIView *containerView;

@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) YSCVoiceWaveView *voiceWaveView;
@property (nonatomic, strong) UIView *voiceWaveParentView;

@property (nonatomic, strong) YSCNewVoiceWaveView *voiceWaveViewNew;
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

// 绘制话筒相关
/**
 *  话筒线的layer
 */
@property (nonatomic,strong,nullable) CAShapeLayer * outsideLineLayer;
/**
 *  话筒layer
 */
@property (nonatomic,strong,nullable) CAShapeLayer * colidLayer;
/**
 *  圆弧layer
 */
@property (nonatomic,strong,nullable) CAShapeLayer * arcLayer;
/**
 *  话筒宽度
 */
@property (nonatomic,assign) CGFloat colidWidth;
/**
 *  话筒线的宽度
 */
@property (nonatomic,assign) CGFloat outsideLineWidth;
/**
 *  线宽
 */
@property (nonatomic,assign) CGFloat lineWidth;
/**
 *  线的颜色
 */
@property (nonatomic,strong) UIColor * lineColor;
/**
 *  话筒颜色
 */
@property (nonatomic,strong) UIColor * colidColor;

@end

@implementation SSChatKeyBordVoiceView{
    BOOL _resetStatus;
}

- (void)dealloc {
    [self invalidate];
}

- (void)invalidate {
    [_updateVolumeTimer invalidate];
    _updateVolumeTimer = nil;
    [_recorder stop];
    _recorder = nil;
    [_voiceWaveView removeFromParent];
    [_voiceWaveViewNew removeFromParent];
    [_loadingView stopLoading];
    _voiceWaveView = nil;
    _voiceWaveViewNew = nil;
}

-(instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        [self initUI];
    }
    return self;
    
}

- (void)initUI {

    self.backgroundColor = SSChatCellColor;
    self.userInteractionEnabled = YES;
    self.colidWidth = 1;
    self.outsideLineWidth = 1;
    self.lineWidth = 1;
    self.lineColor = UIColor.clearColor;
    self.colidColor = UIColor.clearColor;
    
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
    
    [[NSRunLoop currentRunLoop] addTimer:self.updateVolumeTimer forMode:NSDefaultRunLoopMode];
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
    [self.recorder updateMeters];
    CGFloat normalizedValue = pow (10, [self.recorder averagePowerForChannel:0] / 20);
    [_voiceWaveViewNew changeVolume:normalizedValue];
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
    [self voiceWaveShowButtonTouched:nil];
}

- (void)voiceWaveShowButtonTouched:(UIButton *)sender
{
    static NSInteger status = 0;
    status++;
    if (_resetStatus) {
        status = 0;
        [self.recorder stop];
        [self.voiceWaveViewNew stopVoiceWaveWithShowLoadingViewCallback:nil];
    }
    if (status % 3 == 0) { // 识别中状态 --> 休眠状态
        if (!_resetStatus) {
            [self playVoice:@"stop.mp3"];
        }
        [self.loadingView stopLoading];
        [self.updateVolumeTimer invalidate];
        _updateVolumeTimer = nil;
        [self.sleepingView startLoadingInParentView:self.containerView];
    } else if (status % 3 == 1) { // 休眠状态 --> 录音状态
        if (!_resetStatus) {
            [self playVoice:@"start.mp3"];
        }
        [self.sleepingView stopLoading];
        [self.voiceWaveViewNew showInParentView:self.voiceWaveParentViewNew];
        [self.voiceWaveViewNew startVoiceWave];
        [self addCirlAnimationTo:self.voiceIconRotatingView];
        [[NSRunLoop currentRunLoop] addTimer:self.updateVolumeTimer forMode:NSRunLoopCommonModes];
        [self.recorder record]; // 开始录音
    } else { // 录音状态 --> 识别中状态
        [self.recorder stop];
        [self.voiceWaveViewNew stopVoiceWaveWithShowLoadingViewCallback:^{
            [self.updateVolumeTimer invalidate];
            _updateVolumeTimer = nil;
            [self stopCirlAnimationTo:self.voiceIconRotatingView];
            [self.loadingView startLoadingInParentView:self.containerView];
        }];
    }
    _resetStatus = NO;
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

- (YSCNewVoiceWaveView *)voiceWaveViewNew
{
    if (!_voiceWaveViewNew) {
        self.voiceWaveViewNew = [[YSCNewVoiceWaveView alloc] init];
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
        _voiceWaveShowButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        _voiceWaveShowButton.userInteractionEnabled = YES;
        _voiceWaveShowButton.center = self.containerView.center;
        [_voiceWaveShowButton addTarget:self action:@selector(voiceWaveShowButtonTouched:) forControlEvents:UIControlEventTouchDown];
        //中间麦克风图
        UIImageView *imgMicrophone = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 16, 24)];
        //imgMicrophone.center = CGPointMake(30, 30);
        imgMicrophone.center = CGPointMake(30, 29); // 不知道为啥偏下了一点。。
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

#pragma mark - generate

// 代码绘制话筒，放弃。。
- (CAShapeLayer *)generateVoiceIconShapeLayer
{
    CAShapeLayer *waveline = [CAShapeLayer layer];
    waveline.lineCap = kCALineCapButt;
    waveline.lineJoin = kCALineJoinRound;
    waveline.strokeColor = [UIColor redColor].CGColor;
    waveline.fillColor = [[UIColor clearColor] CGColor];
    waveline.lineWidth = self.lineWidth;
    waveline.backgroundColor = [UIColor greenColor].CGColor;
    
    UIBezierPath *path = [self generatePaths];
    waveline.path = path.CGPath;
    
    return waveline;
}

- (UIBezierPath *)generatePaths{
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    CGFloat width = self.voiceIcon.width;
    CGFloat height = self.voiceIcon.height;
    
    //话筒内部
    CGRect colidViewRect = CGRectMake(0, 0, width*0.5, height*0.7);
    UIBezierPath *colidPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(width*0.5/2, 0, colidViewRect.size.width, colidViewRect.size.height) cornerRadius:colidViewRect.size.width*0.4];
    [path appendPath:colidPath];
    
    //话筒边框
    CGRect outsideLineRect = CGRectMake(0, 0, width*0.5, height*0.7);
    UIBezierPath *outsideLinePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(width*0.5/2, 0, outsideLineRect.size.width, outsideLineRect.size.height) cornerRadius:outsideLineRect.size.width*0.4];
    [path appendPath:outsideLinePath];
    
    //话筒弧
    CGRect arcViewRect = CGRectMake(0, 0, width, height*0.7);
    UIBezierPath *arcViewPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(arcViewRect), CGRectGetMidY(arcViewRect)) radius:arcViewRect.size.width*0.6 startAngle:PQ_RADIANS(-5) endAngle:PQ_RADIANS(185) clockwise:YES];
    [path appendPath:arcViewPath];
    return path;
}

- (CAShapeLayer*)drawARCLine:(CGPoint)point frame:(CGRect)frame color:(UIColor*)color{
    CAShapeLayer * Layer = [CAShapeLayer new];
    Layer.fillColor = nil; //这个是填充颜色
    Layer.strokeColor = color.CGColor; //这个边框颜色
    Layer.frame = frame; //这个是大小
    Layer.lineWidth = self.lineWidth; //这个是线宽
    Layer.lineCap = kCALineCapRound; //这个我也不知道
    //这个就是画图
    Layer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(point.x, point.y) radius:frame.size.width*0.3 startAngle:PQ_RADIANS(-5) endAngle:PQ_RADIANS(185) clockwise:YES].CGPath;
    return Layer;
}

- (CAShapeLayer*)drawOutSideLine:(CGRect)frame color:(UIColor*)color isFill:(BOOL)fill {
    CAShapeLayer * Layer = [CAShapeLayer new];
    if (fill) {
        Layer.fillColor = color.CGColor;
        Layer.strokeColor = nil;
    }
    else{
        Layer.fillColor = nil; //这个是填充颜色
        Layer.strokeColor = color.CGColor; //这个边框颜色
    }
    
    Layer.frame = frame; //这个是大小
    Layer.lineWidth = self.lineWidth; //这个是线宽
    Layer.lineCap = kCALineCapRound; //这个我也不知道
    //这个就是画图
    Layer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, frame.size.width, frame.size.height)  cornerRadius:frame.size.width*0.4].CGPath;
    return Layer;
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
        self.updateVolumeTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(updateVolume:) userInfo:nil repeats:YES];
    }
    
    return _updateVolumeTimer;
}

@end
