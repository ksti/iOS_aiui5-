//
//  SSChatMessagelLayout.m
//  SSChatView
//
//  Created by soldoros on 2018/10/12.
//  Copyright © 2018年 soldoros. All rights reserved.
//

#import "SSChatMessagelLayout.h"
#import "SSChatDatas.h"
#import "SSChatIMEmotionModel.h"
#import "SSKit.h"
#import "YYKit.h"


//gif框架 FLAnimatedImageView

@implementation SSChatMessagelLayout

//根据模型返回布局
-(instancetype)initWithMessage:(SSChatMessage *)chatMessage{
    if(self = [super init]){
        _readHeight = 0.0;
        self.chatMessage = chatMessage;
    }
    return self;
}

-(void)setChatMessage:(SSChatMessage *)chatMessage{
    _chatMessage = chatMessage;
    
    switch (_chatMessage.messageType) {
            
        case SSChatMessageTypeText:
            [self setText];
            break;
            
        default:
            break;
    }
}


//显示文字消息 这个自适应计算有误差 用sizeToFit就比较完美 有好办法告诉我
-(void)setText{
    
    _textLabRect = [NSObject getRectWith:_chatMessage.attTextString width:SSChatTextInitWidth];
    
    CGFloat textWidth  = _textLabRect.size.width;
    CGFloat textHeight = _textLabRect.size.height;
    
    CGFloat backTop = 0;
    
    if(_chatMessage.messageFrom == SSChatMessageFromOther){
        
        _readHeight = SSChatReadLabBottom;
        
        _headerImgRect = CGRectMake(SSChatIconLeft,SSChatCellTop, SSChatIconWH, SSChatIconWH);
        
       
        _backImgButtonRect = CGRectMake(SSChatIconLeft+SSChatIconWH+SSChatIconRight, self.headerImgRect.origin.y + backTop, textWidth+SSChatTextLRB+SSChatTextLRS, textHeight+SSChatTextTop+SSChatTextBottom);
        
        _imageInsets = UIEdgeInsetsMake(SSChatAirTop, SSChatAirLRB, SSChatAirBottom, SSChatAirLRS);
        
        _textLabRect.origin.x = SSChatTextLRB;
        _textLabRect.origin.y = SSChatTextTop;
        
    }else{
        
        _readHeight = SSChatReadLabBottom;
        
        _headerImgRect = CGRectMake(SSChatIcon_RX, SSChatCellTop, SSChatIconWH, SSChatIconWH);
        
        _backImgButtonRect = CGRectMake(SSChatIcon_RX-SSChatDetailRight-SSChatTextLRB-textWidth-SSChatTextLRS, self.headerImgRect.origin.y, textWidth+SSChatTextLRB+SSChatTextLRS, textHeight+SSChatTextTop+SSChatTextBottom);
        
        _imageInsets = UIEdgeInsetsMake(SSChatAirTop, SSChatAirLRS, SSChatAirBottom, SSChatAirLRB);
        
        _textLabRect.origin.x = SSChatTextLRS;
        _textLabRect.origin.y = SSChatTextTop;
    }
    
    
    //判断时间是否显示
    _timeLabRect = CGRectMake(0, 0, 0, 0);
    
    if(_chatMessage.showTime==YES){
        
        [self getTimeLabRect];
        
        CGRect hRect = self.headerImgRect;
        hRect.origin.y = SSChatTimeTop+SSChatTimeBottom+SSChatTimeHeight;
        self.headerImgRect = hRect;
        
        _backImgButtonRect = CGRectMake(_backImgButtonRect.origin.x, _headerImgRect.origin.y + backTop, _backImgButtonRect.size.width, _backImgButtonRect.size.height);
    }
    
    _cellHeight = _backImgButtonRect.size.height + _backImgButtonRect.origin.y + backTop + SSChatCellBottom + _readHeight;
    
}

- (void)hideHeaderImage {
    CGRect headerImgRect = _headerImgRect;
    CGRect backImgButtonRect = _backImgButtonRect;
    if(_chatMessage.messageFrom == SSChatMessageFromOther){
        
        _headerImgRect = CGRectMake(headerImgRect.origin.x,headerImgRect.origin.y, 0, 0);
        _backImgButtonRect = CGRectMake(backImgButtonRect.origin.x-headerImgRect.size.width-SSChatIconRight, backImgButtonRect.origin.y, backImgButtonRect.size.width, backImgButtonRect.size.height);
        
    }else{
        
        _headerImgRect = CGRectMake(headerImgRect.origin.x,headerImgRect.origin.y, 0, 0);
        
        _backImgButtonRect = CGRectMake(backImgButtonRect.origin.x+headerImgRect.size.width+SSChatIconRight, backImgButtonRect.origin.y, backImgButtonRect.size.width, backImgButtonRect.size.height);
    }
}


//获取时间的frame值
-(void)getTimeLabRect{
    CGRect timeRect = [NSObject getRectWith:_chatMessage.messageTime width:SSChatTimeWidth font:[UIFont systemFontOfSize:SSChatTimeFont] spacing:0 Row:0];
    CGFloat timeWidth = timeRect.size.width+20;
    _timeLabRect = CGRectMake((SCREEN_Width - timeWidth)/2, SSChatTimeTop, timeWidth, SSChatTimeHeight);
}


@end
