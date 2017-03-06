//
//  WWZSocketRequest.h
//  wwz
//
//  Created by wwz on 16/6/17.
//  Copyright © 2016年 cn.szwwz. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WWZTCPSocketClient;

extern NSString *const NOTI_PREFIX;// 通知前缀

@interface WWZSocketRequest : NSObject

/**
 *  设置socket及协议格式参数
 *
 *  @param tcpSocket WWZTCPSocketClient
 *  @param app_param app default is "wifi"
 *  @param co_param  co default is "kjd"
 */
+ (void)setTcpSocket:(WWZTCPSocketClient *)tcpSocket
            appParam:(NSString *)app_param
            co_param:(NSString *)co_param;


/**
 *  SOCKET请求
 *  @param apiName      接口名
 *  @param parameters   参数：json格式的字典
 *  @param success      success回调
 *  @param failure      failure回调
 */
+ (void)SOCKET:(NSString *)apiName
    parameters:(id)parameters
       success:(void(^)(id result))success
       failure:(void(^)(NSError *error))failure;
/**
 *  SOCKET请求
 *
 *  @param tcpSocket    WWZTCPSocketClient
 *  @param apiName      接口名
 *  @param parameters   参数：json格式的字典
 *  @param success      success回调
 *  @param failure      failure回调
 */
+ (void)SOCKET:(WWZTCPSocketClient *)tcpSocket
       apiName:(NSString *)apiName
    parameters:(id)parameters
       success:(void(^)(id result))success
       failure:(void(^)(NSError *error))failure;

/**
 *  SOCKET请求
 *
 *  @param apiName      接口名
 *  @param message      发送的完整消息指令
 *  @param success      success回调
 *  @param failure      failure回调
 */
+ (void)SOCKET:(NSString *)apiName
       message:(NSString *)message
       success:(void(^)(id result))success
       failure:(void(^)(NSError *error))failure;

/**
 *  SOCKET请求
 *
 *  @param tcpSocket    WWZTCPSocketClient
 *  @param apiName      接口名
 *  @param message      发送的完整消息指令
 *  @param success      success回调
 *  @param failure      failure回调
 */
+ (void)SOCKET:(WWZTCPSocketClient *)tcpSocket
       apiName:(NSString *)apiName
       message:(NSString *)message
       success:(void(^)(id result))success
       failure:(void(^)(NSError *error))failure;

/**
 *  设置请求超时时间
 *
 *  @param timeOut 超时时间， default is 10s
 */
+ (void)setSocketRequsetTimeOut:(NSTimeInterval)timeOut;

@end
