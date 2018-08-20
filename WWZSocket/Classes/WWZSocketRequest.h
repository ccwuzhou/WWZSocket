//
//  WWZSocketRequest.h
//  wwz
//
//  Created by wwz on 16/6/17.
//  Copyright © 2016年 cn.szwwz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WWZResponseModel.h"
@class WWZTCPSocketClient;

@interface WWZSocketRequest : NSObject

/**
 *  socket client
 */
@property (nonatomic, strong) WWZTCPSocketClient *tcpSocket;

/**
 *  超时时间
 */
@property (nonatomic, assign) NSTimeInterval requestTimeout;

+ (instancetype)shareInstance;

/**
 *  SOCKET请求
 *  @param api          接口名
 *  @param parameters   参数：json格式的字典
 *  @param success      success回调
 *  @param failure      failure回调
 */
- (void)request:(NSString *)api
     parameters:(id)parameters
        success:(void(^)(WWZResponseModel *result))success
        failure:(void(^)(NSError *error))failure;

/**
 *  SOCKET请求
 *
 *  @param socket       WWZTCPSocketClient
 *  @param api          接口名
 *  @param parameters   参数：json格式的字典
 *  @param success      success回调
 *  @param failure      failure回调
 */
- (void)request:(WWZTCPSocketClient *)socket
            api:(NSString *)api
     parameters:(id)parameters
        success:(void(^)(WWZResponseModel *result))success
        failure:(void(^)(NSError *error))failure;

/**
 *  SOCKET请求
 *
 *  @param api          接口名
 *  @param message      发送的完整消息指令
 *  @param success      success回调
 *  @param failure      failure回调
 */
- (void)request:(NSString *)api
        message:(NSString *)message
        success:(void(^)(WWZResponseModel *result))success
        failure:(void(^)(NSError *error))failure;

/**
 *  SOCKET请求
 *
 *  @param socket       WWZTCPSocketClient
 *  @param api          接口名
 *  @param message      发送的完整消息指令
 *  @param success      success回调
 *  @param failure      failure回调
 */
- (void)request:(WWZTCPSocketClient *)socket
            api:(NSString *)api
        message:(NSString *)message
        success:(void(^)(WWZResponseModel *result))success
        failure:(void(^)(NSError *error))failure;

/**
 *  SOCKET请求
 *
 *  @param socket       WWZTCPSocketClient
 *  @param api          接口名
 *  @param data         发送的完整消息指令
 *  @param success      success回调
 *  @param failure      failure回调
 */
- (void)request:(WWZTCPSocketClient *)socket
            api:(NSString *)api
           data:(NSData *)data
        success:(void(^)(WWZResponseModel *result))success
        failure:(void(^)(NSError *error))failure;
@end
