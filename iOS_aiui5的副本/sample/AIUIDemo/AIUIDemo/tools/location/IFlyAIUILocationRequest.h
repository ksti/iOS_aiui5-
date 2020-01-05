/*
 * IFlyAIUILocationRequest.h
 * AIUIDemo
 *
 *  Created on: 2018年1月1日
 *      Author: 讯飞AIUI开放平台（http://aiui.xfyun.cn）
 */

#ifndef LocationRequest_h
#define LocationRequest_h

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>



@interface IFlyAIUILocationRequest : NSObject <CLLocationManagerDelegate>
{
    CLLocationManager *iFlyLocManager;
}

//request location info
- (void)locationAsynRequest;

//get location info
-(CLLocation *) getLocation;

@end


#endif /* LocationRequest_h */
