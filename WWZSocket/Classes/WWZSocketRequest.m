//
//  WWZSocketRequest.m
//  WWZSocket
//
//  Created by wwz on 16/6/17.
//

#import "WWZSocketRequest.h"
#import "WWZTCPSocketClient.h"
#import "WWZRequestModel.h"
#import <objc/runtime.h>

@interface WWZSocketRequestModel : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger timestamp;
@property (nonatomic, copy) void(^success)(WWZResponseModel *);
@property (nonatomic, copy) void(^failure)(NSError *);

- (instancetype)initWithName:(NSString *)name success:(void(^)(WWZResponseModel *))success failure:(void(^)(NSError *))failure;

@end

@implementation WWZSocketRequestModel

- (instancetype)initWithName:(NSString *)name success:(void(^)(WWZResponseModel *))success failure:(void(^)(NSError *))failure
{
    self = [super init];
    if (self) {
        self.name = name;
        self.timestamp = [[NSDate date] timeIntervalSince1970];
        self.success = success;
        self.failure = failure;
    }
    return self;
}

@end


@interface WWZSocketRequest (){
    dispatch_queue_t _queue;
}

@property (nonatomic, strong) NSMutableArray *mRequestModels;
@property (nonatomic, strong) NSTimer *timer;

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
        _mRequestModels = [NSMutableArray array];
        _requestTimeout = 10;
        _queue = dispatch_queue_create("WWZSocketRequestQueue", DISPATCH_QUEUE_SERIAL);
        _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
    }
    return self;
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
        success:(void(^)(WWZResponseModel *result))success
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
        success:(void(^)(WWZResponseModel *result))success
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
        success:(void(^)(WWZResponseModel *result))success
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
        success:(void(^)(WWZResponseModel *result))success
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
        success:(void(^)(WWZResponseModel *result))success
        failure:(void(^)(NSError *error))failure{
    NSString *noti_name = [NSString stringWithFormat:@"%@_%@", NOTI_PREFIX, api];
    if (!success && !failure) {
        [socket sendDataToSocketWithData:data];
        return;
    }
    // 添加通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_get_result_noti:) name:noti_name object:nil];
    // 发送请求
    [socket sendDataToSocketWithData:data];
    WWZSocketRequestModel *model = [[WWZSocketRequestModel alloc] initWithName:noti_name success:success failure:failure];
    [self.mRequestModels addObject:model];
//    // 超时处理
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.requestTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        for (WWZSocketRequestModel *model in self.mRequestModels) {
//            if ([model.name isEqualToString:noti_name] && model.failure) {
//                NSNotification *noti = [NSNotification notificationWithName:noti_name object:nil userInfo:nil];
//                [self p_get_result_noti:noti];
//            }
//        }
//    });
}
#pragma mark - 通知
/**
 *  收到通知，通知名"wwz_[api_name]"
 *
 *  @param noti @{retcode : retmsg}
 */
- (void)p_get_result_noti:(NSNotification *)noti{
    dispatch_sync(_queue, ^{
        WWZSocketRequestModel *removeModel = nil;
        for (WWZSocketRequestModel *model in self.mRequestModels) {
            if (![model.name isEqualToString:noti.name]) {
                continue;
            }
            removeModel = model;
            if (noti.object) {// 成功
                model.success(noti.object);
            }else {// 失败
                NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{@"error": @"request time out"}];
                model.failure(error);
            }
            break;
        }
        // 移除block
        [self.mRequestModels removeObject:removeModel];
        if ([self p_canRemoveObserver:noti.name]) {
            // 移除通知
            [[NSNotificationCenter defaultCenter] removeObserver:self name:noti.name object:nil];
        }
    });
}

- (BOOL)p_canRemoveObserver:(NSString *)name{
    for (WWZSocketRequestModel *model in self.mRequestModels) {
        if ([model.name isEqualToString:name]) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - private method
- (void)timerAction{
    NSMutableArray<WWZSocketRequestModel *> *mArr = [NSMutableArray array];
    for (WWZSocketRequestModel *model in self.mRequestModels) {
        if ([[NSDate date] timeIntervalSince1970] - model.timestamp > self.requestTimeout && model.failure) {
            [mArr addObject:model];
        }
    }
    for (WWZSocketRequestModel *model in mArr) {
        NSNotification *noti = [NSNotification notificationWithName:model.name object:nil userInfo:nil];
        [self p_get_result_noti:noti];
    }
}
#pragma mark - help
/**
 *  格式化指令
 */
- (NSString *)p_formatCmdWithApiName:(NSString *)apiName parameters:(id)parameters{
    NSError *error = nil;
    WWZRequestModel *requestModel = [[WWZRequestModel alloc] initWithApi:apiName data:parameters];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self dictionayFromModelPropertiesWithObj:requestModel] options:NSJSONWritingPrettyPrinted error:&error];
    if (error) return nil;
    NSString *param = [[[[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"  \"" withString:@"\""] stringByReplacingOccurrencesOfString:@" : " withString:@":"];
    return [NSString stringWithFormat:@"%@\n",param];
}

- (NSMutableDictionary *)dictionayFromModelPropertiesWithObj:(id)obj{
    NSMutableDictionary *propsDic = [NSMutableDictionary dictionary];
    unsigned int outCount, i;
    // class:获取哪个类的成员属性列表
    // count:成员属性总数
    // 拷贝属性列表
    objc_property_t *properties = class_copyPropertyList([obj class], &outCount);
    for (i = 0; i<outCount; i++) {
        objc_property_t property = properties[i];
        const char* char_f = property_getName(property);
        // 属性名
        NSString *propertyName = [NSString stringWithUTF8String:char_f];
        // 属性值
        id propertyValue = [obj valueForKey:(NSString *)propertyName];
        // 设置KeyValues
        if (propertyValue) [propsDic setObject:propertyValue forKey:propertyName];
    }
    // 需手动释放 不受ARC约束
    free(properties);
    return propsDic;
}

@end
