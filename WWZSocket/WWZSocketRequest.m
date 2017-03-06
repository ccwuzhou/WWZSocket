//
//  WWZSocketRequest.m
//  wwz
//
//  Created by wwz on 16/6/17.
//  Copyright © 2016年 cn.szwwz. All rights reserved.
//

#import "WWZSocketRequest.h"
#import "WWZTCPSocketClient.h"

typedef void(^kCallBackBlock)(id) ;

NSString *const NOTI_PREFIX = @"wwz";

static NSString *APP_PARAM = @"wifi";
static NSString *CO_PARAM = @"kjd";

// @[@"api": @[@"api_1", @"api_2"]]
static NSMutableDictionary *_mApiDict;

static NSMutableDictionary *_mSuccessBlockDict;
static NSMutableDictionary *_mFailureBlockDict;

static NSTimeInterval _kRequsetTimeOut = 10;

static WWZTCPSocketClient *_tcpScoket = nil;

@implementation WWZSocketRequest

/**
 *  初始化
 */
+ (void)initialize{

    _mApiDict = [NSMutableDictionary dictionary];
    
    _mSuccessBlockDict = [NSMutableDictionary dictionary];
    _mFailureBlockDict = [NSMutableDictionary dictionary];
}

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
       failure:(void(^)(NSError *error))failure{

    if (!_tcpScoket) {
        NSLog(@"请先调用(-setTcpSocket:appParam:co_param:)设置socket相关参数");
        return;
    }
    [self SOCKET:_tcpScoket apiName:apiName parameters:parameters success:success failure:failure];
}

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
       failure:(void(^)(NSError *error))failure{
    
    [self SOCKET:tcpSocket apiName:apiName message:[self formatCmdWithApiName:apiName parameters:parameters] success:success failure:failure];
}

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
       failure:(void(^)(NSError *error))failure{
    
    if (!_tcpScoket) {
        NSLog(@"请先调用(-setTcpSocket:appParam:co_param:)设置socket相关参数");
        return;
    }
    [self SOCKET:_tcpScoket apiName:apiName message:message success:success failure:failure];
}

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
       failure:(void(^)(NSError *error))failure{
    
    NSString *noti_name = [NSString stringWithFormat:@"%@_%@", NOTI_PREFIX, apiName];
    
    if (success) {
        _mSuccessBlockDict[noti_name] = success;
    }
    if (failure) {
        _mFailureBlockDict[noti_name] = failure;
        
        _mFailureBlockDict[ERROR_NOTI_NAME] = failure;
    }
    
    // 添加通知
    if (success||failure) {
        [self addApiWithKey:noti_name];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(get_result_noti:) name:noti_name object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(get_result_noti:) name:ERROR_NOTI_NAME object:nil];
    }
    // 发送请求
    [tcpSocket sendDataToSocketWithString:message];
    
    // 超时处理
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_kRequsetTimeOut* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (!_mFailureBlockDict[noti_name]) {
            return ;
        }
        
        NSNotification *noti = [NSNotification notificationWithName:noti_name object:nil userInfo:@{@"-1" : @"request time out"}];
        
        [self get_result_noti:noti];
        
    });
}
#pragma mark - 通知
/**
 *  收到通知，通知名"wwz_[api_name]"
 *
 *  @param noti @{retcode : retmsg}
 */
+ (void)get_result_noti:(NSNotification *)noti{
    
    [self removeApiWithKey:noti.name];
    
    // 移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self name:noti.name object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ERROR_NOTI_NAME object:nil];
    
    if (!noti.userInfo || noti.userInfo.count == 0) {
        return;
    }
    
    NSInteger retcode = [[noti.userInfo allKeys][0] integerValue];
    
    if (retcode == 0 || retcode == 100) {// 成功
        
        kCallBackBlock success = _mSuccessBlockDict[noti.name];
        
        // 移除block
        [self removeBlockWithKey:noti.name];
        
        if (success) {
            success(noti.object);
        }
        
    }else{// 失败
        
        kCallBackBlock failure = _mFailureBlockDict[noti.name];

        // 移除block
        [self removeBlockWithKey:noti.name];
        
        if (failure) {
            NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:retcode userInfo:@{@"error": [noti.userInfo allValues][0]}];
            failure(error);
        }
    }
}

/**
 *  移除block
 *
 *  @param key key
 */
+ (void)removeBlockWithKey:(NSString *)key{
    
    [_mSuccessBlockDict removeObjectForKey:key];
    [_mFailureBlockDict removeObjectForKey:key];
    [_mFailureBlockDict removeObjectForKey:ERROR_NOTI_NAME];
}
+ (void)addApiWithKey:(NSString *)key{
    
    if (![_mApiDict.allKeys containsObject:key]) {
        
        _mApiDict[key] = [NSMutableArray arrayWithObject:key];
    }else{
        
        NSMutableArray *mArr = _mApiDict[key];
        [mArr addObject:key];
    }
}

+ (void)removeApiWithKey:(NSString *)key{
    
    if (![_mApiDict.allKeys containsObject:key]) return;
    
    NSMutableArray *mArr = _mApiDict[key];
    
    if (mArr.count <= 1) {
        
        [_mApiDict removeObjectForKey:key];
        
    }else{
        
        [mArr removeObjectAtIndex:0];
    }
}
#pragma mark - help
/**
 *  格式化指令
 */
+ (NSString *)formatCmdWithApiName:(NSString *)apiName parameters:(id)parameters{
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:&error];
    
    if (error) return nil;
    
    NSString *param = [[[[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"  \"" withString:@"\""] stringByReplacingOccurrencesOfString:@" : " withString:@":"];
    
    return [NSString stringWithFormat:@"{\"app\":\"%@\",\"co\":\"%@\",\"api\":\"%@\",\"data\":%@}\n", APP_PARAM, CO_PARAM, apiName, param];
}
/**
 *  参数设置
 *
 *  @param tcpSocket tcpSocket
 *  @param app_param app_param
 *  @param co_param  co_param
 */
+ (void)setTcpSocket:(WWZTCPSocketClient *)tcpSocket appParam:(NSString *)app_param co_param:(NSString *)co_param{
    
    if (tcpSocket) {
        _tcpScoket = tcpSocket;
    }
    if (app_param) {
        APP_PARAM = app_param;
    }
    if (co_param) {
        CO_PARAM = co_param;
    }
}

/**
 *  设置请求超时时间
 *
 *  @param timeOut 超时时间
 */
+ (void)setSocketRequsetTimeOut:(NSTimeInterval)timeOut{
    
    _kRequsetTimeOut = timeOut;
    
}
@end
