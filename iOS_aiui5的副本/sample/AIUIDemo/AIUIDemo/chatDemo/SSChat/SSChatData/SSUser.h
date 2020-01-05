//
//  SSUser.h
//  AIUIDemo
//
//  Created by GJS on 2020/1/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SSUserInfo;

/**
 *  用户性别
 */
typedef NS_ENUM(NSInteger, SSUserGender) {
    /**
     *  未知性别
     */
    NIMUserGenderUnknown,
    /**
     *  性别男
     */
    NIMUserGenderMale,
    /**
     *  性别女
     */
    NIMUserGenderFemale,
};

/**
 *  云信用户
 */
@interface SSUser : NSObject

/**
 *  用户Id
 */
@property (nullable,nonatomic,copy)   NSString    *userId;

/**
 *  备注名，长度限制为128个字符。
 */
@property (nullable,nonatomic,copy)   NSString    *alias;

/**
 *  扩展字段
 */
@property (nullable,nonatomic,copy)   NSString  *ext;

/**
 *  服务器扩展字段
 *  @discussion 该字段只能由服务器进行修改，客户端只能读取
 *
 */
@property (nullable,nonatomic,copy)   NSString  *serverExt;

/**
 *  用户资料，仅当用户选择托管信息到云信时有效
 *  用户资料除自己之外，不保证其他用户资料实时更新
 *  其他用户资料更新的时机为: 1.调用 - (void)fetchUserInfos:completion: 方法刷新用户
 *                        2.收到此用户发来消息
 *                        3.程序再次启动，此时会同步好友信息
 */
@property (nullable,nonatomic,strong) SSUserInfo *userInfo;

/**
 *  是否需要消息提醒
 */
@property (nonatomic,assign) BOOL notifyForNewMsg;

/**
 *  是否在黑名单中
 */

@property (nonatomic,assign) BOOL isInMyBlackList;

@end


/**
 *  用户资料，仅当用户选择托管信息到云信时有效
 */
@interface SSUserInfo : NSObject

/**
 *  用户昵称
 */
@property (nullable,nonatomic,copy) NSString *nickName;

/**
 *  用户头像
 */
@property (nullable,nonatomic,copy) NSString *avatarUrl;

/**
 *  用户头像缩略图
 *  @discussion 仅适用于使用云信上传服务进行上传的资源，否则无效。
 */
@property (nullable,nonatomic,copy) NSString *thumbAvatarUrl;

/**
 *  用户签名
 */
@property (nullable,nonatomic,copy) NSString *sign;

/**
 *  用户性别
 */
@property (nonatomic,assign) SSUserGender gender;

/**
 *  邮箱
 */
@property (nullable,nonatomic,copy) NSString *email;

/**
 *  生日
 */
@property (nullable,nonatomic,copy) NSString *birth;

/**
 *  电话号码
 */
@property (nullable,nonatomic,copy) NSString *mobile;

/**
 *  用户自定义扩展字段
 */
@property (nullable,nonatomic,copy) NSString *ext;


@end

NS_ASSUME_NONNULL_END
