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

@interface WWZSocketRequest ()

/**
 *  所有请求api@[@"api": @[@"api", @"api"]]
 */
@property (nonatomic, strong) NSMutableDictionary *mApiDict;

/**
 *  成功回调字典[noti_name: kCallBackBlock]
 */
@property (nonatomic, strong) NSMutableDictionary *mSuccessBlockDict;
/**
 *  失败回调字典[noti_name: kCallBackBlock]
 */
@property (nonatomic, strong) NSMutableDictionary *mFailureBlockDict;

/**
 *  超时时间
 */
@property (nonatomic, assign) NSTimeInterval requestTimeout;

/**
 *  socket client
 */
@property (nonatomic, strong) WWZTCPSocketClient *tcpSocket;

/**
 *  其它请求参数
 */
@property (nonatomic, copy) NSString *app_param;

@property (nonatomic, copy) NSString *co_param;
@end

@implementation WWZSocketRequest

static WWZSocketRequest *_instance;

+ (instancetype)allocWithZone:(struct _NSZone *)zone{

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

+ (instancetype)shareInstance{

    if (!_instance) {
        _instance = [[WWZSocketRequest alloc] init];
    }
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _mApiDict = [NSMutableDictionary dictionary];
        
        _mSuccessBlockDict = [NSMutableDictionary dictionary];
        _mFailureBlockDict = [NSMutableDictionary dictionary];
        
        self.requestTimeout = 10;
        
        self.app_param = @"wwz";
        self.co_param = @"wwz";
    }
    return self;
}
/**
 *  参数设置
 *
 *  @param tcpSocket tcpSocket
 *  @param app_param app_param
 *  @param co_param  co_param
 */
- (void)setTcpSocket:(WWZTCPSocketClient *)tcpSocket app_param:(NSString *)app_param co_param:(NSString *)co_param{
    
    self.tcpSocket = tcpSocket;
    self.app_param = app_param;
    self.co_param = co_param;
}
/**
 *  SOCKET请求
 *  @param api          接口名
 *  @param parameters   参数：json格式的字典
 *  @param success      success回调
 *  @param failure      failure回调
 */
- (void)request:(NSString *)api
    parameters:(id)parameters
       success:(void(^)(id result))success
       failure:(void(^)(NSError *error))failure{

    if (!self.tcpSocket) {
        NSLog(@"请先调用(-setTcpSocket:app_param:co_param:)设置socket相关参数");
        return;
    }
    [self request:self.tcpSocket api:api parameters:parameters success:success failure:failure];
}

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
        success:(void(^)(id result))success
        failure:(void(^)(NSError *error))failure{
    
    NSString *message = [self p_formatCmdWithApiName:api parameters:parameters];
    if (!message) {
        NSLog(@"请求格式不正确");
        return;
    }
    [self request:socket api:api message:message success:success failure:failure];
}

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
        success:(void(^)(id result))success
        failure:(void(^)(NSError *error))failure{
    
    if (!self.tcpSocket) {
        NSLog(@"请先调用(-setTcpSocket:app_param:co_param:)设置socket相关参数");
        return;
    }
    [self request:self.tcpSocket api:api message:message success:success failure:failure];
}
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
        success:(void(^)(id result))success
        failure:(void(^)(NSError *error))failure{

    NSData *data = [[message stringByReplacingOccurrencesOfString:@"'" withString:@""] dataUsingEncoding:NSUTF8StringEncoding];
    [self request:socket api:api data:data success:success failure:failure];
}

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
       success:(void(^)(id result))success
       failure:(void(^)(NSError *error))failure{
    
    NSString *noti_name = [NSString stringWithFormat:@"%@_%@", NOTI_PREFIX, api];
    
    if (success) {
        self.mSuccessBlockDict[noti_name] = success;
    }
    if (failure) {
        self.mFailureBlockDict[noti_name] = failure;
    }
    
    // 添加通知
    if (success||failure) {
        [self p_insertApiWithKey:noti_name];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_get_result_noti:) name:noti_name object:nil];
    }
    // 发送请求
    [socket sendDataToSocketWithData:data];
    
    // 超时处理
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.requestTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (!self.mFailureBlockDict[noti_name]) return ;
        
        NSNotification *noti = [NSNotification notificationWithName:noti_name object:nil userInfo:@{@"-1" : @"request time out"}];
        
        [self p_get_result_noti:noti];
        
    });
}
#pragma mark - 通知
/**
 *  收到通知，通知名"wwz_[api_name]"
 *
 *  @param noti @{retcode : retmsg}
 */
- (void)p_get_result_noti:(NSNotification *)noti{
    
    [self p_removeApiWithKey:noti.name];
    
    // 移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self name:noti.name object:nil];
    
    if (!noti.userInfo || noti.userInfo.count == 0) return;
    
    NSInteger retcode = [[noti.userInfo allKeys][0] integerValue];
    
    if (retcode == 0 || retcode == 100) {// 成功
        
        kCallBackBlock success = self.mSuccessBlockDict[noti.name];
        
        if (success) {
            success(noti.object);
        }
        
    }else{// 失败
        
        kCallBackBlock failure = self.mFailureBlockDict[noti.name];

        if (failure) {
            NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:retcode userInfo:@{@"error": [noti.userInfo allValues][0]}];
            failure(error);
        }
    }
    // 移除block
    [self.mSuccessBlockDict removeObjectForKey:noti.name];
    [self.mFailureBlockDict removeObjectForKey:noti.name];
}

- (void)p_insertApiWithKey:(NSString *)key{
    
    if (![self.mApiDict.allKeys containsObject:key]) {
        
        self.mApiDict[key] = [NSMutableArray arrayWithObject:key];
    }else{
        
        NSMutableArray *mArr = self.mApiDict[key];
        [mArr addObject:key];
    }
}

- (void)p_removeApiWithKey:(NSString *)key{
    
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
- (NSString *)p_formatCmdWithApiName:(NSString *)apiName parameters:(id)parameters{
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:&error];
    
    if (error) return nil;
    
    NSString *param = [[[[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"  \"" withString:@"\""] stringByReplacingOccurrencesOfString:@" : " withString:@":"];
    
    return [NSString stringWithFormat:@"{\"app\":\"%@\",\"co\":\"%@\",\"api\":\"%@\",\"data\":%@}\n", self.app_param, self.co_param, apiName, param];
}


@end
