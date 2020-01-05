//
//  SSChatBaseCell.m
//  SSChatView
//
//  Created by soldoros on 2018/10/9.
//  Copyright © 2018年 soldoros. All rights reserved.
//

#import "SSChatBaseCell.h"
#import "SSKit.h"
#import "YYKit.h"
#import "SSUser.h"
#import "SSChatDatas.h"

@implementation SSChatBaseCell


-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]){
        // Remove touch delay for iOS 7
        for (UIView *view in self.subviews) {
            if([view isKindOfClass:[UIScrollView class]]) {
                ((UIScrollView *)view).delaysContentTouches = NO;
                break;
            }
        }
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = SSChatCellColor;
        self.contentView.backgroundColor = SSChatCellColor;
        [self initSSChatCellUserInterface];
    }
    return self;
}


-(void)initSSChatCellUserInterface{
    
    // 2、创建头像
    _mHeaderImgBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _mHeaderImgBtn.backgroundColor =  [UIColor brownColor];
    _mHeaderImgBtn.tag = 10;
    _mHeaderImgBtn.userInteractionEnabled = YES;
    [self.contentView addSubview:_mHeaderImgBtn];
    _mHeaderImgBtn.clipsToBounds = YES;
    [_mHeaderImgBtn setImage:[UIImage imageNamed:@"user_avatar_blue"] forState:UIControlStateNormal];
    [_mHeaderImgBtn addTarget:self action:@selector(headerButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    _mFriendLab = [UILabel new];
    _mFriendLab.bounds = CGRectMake(0, 0, 0, 0);
    [self.contentView addSubview:_mFriendLab];
    _mFriendLab.textAlignment = NSTextAlignmentCenter;
    _mFriendLab.font = [UIFont systemFontOfSize:12];
    _mFriendLab.textColor = [UIColor grayColor];

    //创建时间
    _mMessageTimeLab = [UILabel new];
    _mMessageTimeLab.bounds = CGRectMake(0, 0, SSChatTimeWidth, SSChatTimeHeight);
    _mMessageTimeLab.top = SSChatTimeTop;
    _mMessageTimeLab.centerX = SCREEN_Width*0.5;
    [self.contentView addSubview:_mMessageTimeLab];
    _mMessageTimeLab.textAlignment = NSTextAlignmentCenter;
    _mMessageTimeLab.font = [UIFont systemFontOfSize:SSChatTimeFont];
    _mMessageTimeLab.textColor = [UIColor whiteColor];
    _mMessageTimeLab.backgroundColor = makeColorRgb(220, 220, 220);
    _mMessageTimeLab.clipsToBounds = YES;
    _mMessageTimeLab.layer.cornerRadius = 3;
    
    
    //背景按钮
    _mBackImgButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _mBackImgButton.backgroundColor =  [SSChatCellColor colorWithAlphaComponent:0.4];
    _mBackImgButton.tag = 50;
    [self.contentView addSubview:_mBackImgButton];
    [_mBackImgButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    

    _mReadLab = [UILabel new];
    _mReadLab.bounds = CGRectMake(0, 0, 0, 0);
    [self.contentView addSubview:_mReadLab];
    _mReadLab.textAlignment = NSTextAlignmentCenter;
    _mReadLab.font = [UIFont systemFontOfSize:12];
    _mReadLab.textColor = TitleColor;
    
}


-(BOOL)canBecomeFirstResponder{
    return YES;
}


-(void)setLayout:(SSChatMessagelLayout *)layout{
    _layout = layout;
    
    _mMessageTimeLab.hidden = !layout.chatMessage.showTime;
    _mMessageTimeLab.text = layout.chatMessage.messageTime;
    _mMessageTimeLab.frame = layout.timeLabRect;
    
    self.mHeaderImgBtn.frame = layout.headerImgRect;
    self.mHeaderImgBtn.layer.cornerRadius = self.mHeaderImgBtn.height*0.5;
    
    [self.mHeaderImgBtn setBackgroundImage:[UIImage imageNamed:@"touxaing2"] forState:UIControlStateNormal];
    
    if(_layout.chatMessage.messageFrom == SSChatMessageFromOther){
        [self.mHeaderImgBtn setBackgroundImage:[UIImage imageNamed:@"touxiang1"] forState:UIControlStateNormal];
    }
    NSString *uid = kFromId;
    SSUser *user = [SSUser new];
    user.userId = uid;
    NSString *avatarUrl = user.userInfo.avatarUrl;
    if(avatarUrl == nil)avatarUrl = @"";
    [self.mHeaderImgBtn setImageWithURL:[NSURL URLWithString:avatarUrl] forState:UIControlStateNormal options:YYWebImageOptionProgressive];
   
}

//头像10
-(void)headerButtonPressed:(UIButton *)sender{
    if(_delegate && [_delegate respondsToSelector:@selector(SSChatHeaderImgCellClick:indexPath:)]){
        [_delegate SSChatHeaderImgCellClick:self.layout indexPath:self.indexPath];
    }
}

//消息按钮50
-(void)buttonPressed:(UIButton *)sender{
   
}

//设置已读未读
-(void)setMessageReadStatus{
    
    _mReadLab.hidden = YES;
}


@end
