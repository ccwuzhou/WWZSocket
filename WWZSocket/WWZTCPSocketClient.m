//
//  WWZTCPSocketClient.m
//  SmartHome_iPad
//
//  Created by wwz on 16/3/2.
//  Copyright © 2016年 zgkjd. All rights reserved.
//

#import "WWZTCPSocketClient.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>

#ifdef DEBUG // 调试

#define WZLog(fmt, ...) NSLog((@"%s " fmt), __PRETTY_FUNCTION__, ##__VA_ARGS__)

#else // 发布

#define WZLog(...)

#endif

// G-C-D
// 主线程
#define WZ_MAIN_GCD(block) dispatch_async(dispatch_get_main_queue(),block)

NSString *const ERROR_NOTI_NAME = @"wwz_error_noti";

@interface WWZTCPSocketClient ()<GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *socket;

@end

@implementation WWZTCPSocketClient

@synthesize isConnecting = _isConnecting;

static int const connectTimeOut = 4;

static int const kReadTimeOut = -1;

static int const kWriteDataTag = 1;

static int const kReadDataTag = 0;


- (instancetype)initWithDelegate:(id<WWZTCPSocketDelegate>)delegate endKey:(NSString *)endKey
{
    self = [self init];
    if (self) {
        
        self.tcpDelegate = delegate;
        
        if (endKey) {
            
            _endKey = endKey;
        }
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
//        _endKey = @"\n";
    }
    return self;
}


#pragma mark - 连接socket
- (void)connectToHost:(NSString*)host onPort:(uint16_t)port{

    _isConnecting = YES;
    
    [self disconnectSocket];
    
    NSError *error = nil;
    
    if (![self.socket connectToHost:[self p_convertedHostFromHost:host] onPort:port withTimeout:connectTimeOut error:&error]||error) {
        WZLog(@"connect fail error：%@", error);
    }
}

#pragma mark - 断开socket
- (void)disconnectSocket{
    
    if (self.socket.isConnected) {
        
        [self.socket disconnect];
        
        WZLog(@"disconnect socket");
    }
}

#pragma mark - 发送请求
- (void)sendDataToSocketWithString:(NSString *)string{
    
    if (!string||string.length == 0) {
        return;
    }
    if ([string rangeOfString:@"'"].length>0) {
        string = [string stringByReplacingOccurrencesOfString:@"'" withString:@""];
    }
    WZLog(@"%@", string);
    // 根据服务器要求发送固定格式的数据
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    [self sendDataToSocketWithData:data];
    
}
- (void)sendDataToSocketWithData:(NSData *)data{

    if (!data||data.length == 0) {
        return;
    }
    [self.socket writeData:data withTimeout:-1 tag:kWriteDataTag];
}
#pragma mark - GCDAsyncSocketDelegate
#pragma mark - 连接成功回调
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    
    WZLog(@"+++connect to server success+++");
    
    _isConnecting = NO;

    WZ_MAIN_GCD(^{
        if ([self.tcpDelegate respondsToSelector:@selector(tcpSocket:didConnectToHost:port:)]) {
            [self.tcpDelegate tcpSocket:self didConnectToHost:host port:port];
        }
    });
    
    [self p_readData];

}
#pragma mark - socket断线回调
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{

    WZLog(@"+++socket disconnect+++");
    
    _isConnecting = NO;
    
    WZ_MAIN_GCD(^{
        if ([self.tcpDelegate respondsToSelector:@selector(tcpSocket:didDisconnectWithError:)]) {
            [self.tcpDelegate tcpSocket:self didDisconnectWithError:err];
        }
    });
}
#pragma mark - 写成功
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    
    // 写成功后开始读数据
    [self p_readData];
}
#pragma mark - 收到数据回调
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    
    if (!data || data.length == 0) {
        
        [self p_readData];
        
        return;
    }
    if (_endKey) {
        
        if (data.length <= self.endDataKey.length) {
            
            [self p_readData];
            
            return;
        }
        // 删掉最后self.endDataKey'\n'
        data = [data subdataWithRange:NSMakeRange(0, data.length-self.endDataKey.length)];
    }
    
    // data==>string
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    WZLog(@"+++++read data length==>%d+++++", (int)data.length);
    
    if (!text||text.length == 0) {
        
        if (data.length > 0) {
            
            WZ_MAIN_GCD(^{
                
                if ([self.tcpDelegate respondsToSelector:@selector(tcpSocket:didReadResult:)]) {
                    [self.tcpDelegate tcpSocket:self didReadResult:data];
                }
            });
        }
        
        [self p_readData];
        return;
    }
    id jsonResult = [self p_jsonSerializationWithString:text];
    
    NSString *retcode = @"-1";
    
    NSString *retmsg = @"";
    
    if ([jsonResult isKindOfClass:[NSError class]]) {// json 解析失败
        
        retmsg = [[[(NSError *)jsonResult userInfo] allValues] lastObject];
        WZ_MAIN_GCD(^{
        
            [[NSNotificationCenter defaultCenter] postNotificationName:ERROR_NOTI_NAME object:jsonResult userInfo:@{retcode : retmsg}];
        });
        
    }else if (!jsonResult||(![jsonResult isKindOfClass:[NSDictionary class]]&&![jsonResult isKindOfClass:[NSArray class]])){// 不存在或不是字典或数组
        
        retmsg = @"not json format";
        
        WZ_MAIN_GCD(^{
         
            [[NSNotificationCenter defaultCenter] postNotificationName:ERROR_NOTI_NAME object:jsonResult userInfo:@{retcode : retmsg}];
        });
        
    }else{// 有效数据
        
        WZ_MAIN_GCD(^{
            
            if ([self.tcpDelegate respondsToSelector:@selector(tcpSocket:didReadResult:)]) {
                [self.tcpDelegate tcpSocket:self didReadResult:jsonResult];
            }
        });
    }
    // 读完当前数据后继续读数
    [self p_readData];
}
/**
 *  读取数据
 */
- (void)p_readData{

    if (_endKey) {
        // 读到'\n'
        [self.socket readDataToData:self.endDataKey withTimeout:kReadTimeOut tag:kReadDataTag];
    }else{
        [self.socket readDataWithTimeout:kReadTimeOut tag:kReadDataTag];
    }
}

/**
 *  json string ==> 字典
 */
- (id)p_jsonSerializationWithString:(NSString *)jsonString{
    
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    // 转字典
    id result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        return error;
    }else{
        return result;
    }
}

/**
 *  ip转换(ipv6 ip转换)
 *
 *  @param host 旧host
 *
 *  @return 新ip
 */
- (NSString *)p_convertedHostFromHost:(NSString *)host{
    
    NSError *err = nil;
    
    NSMutableArray *addresses = [GCDAsyncSocket lookupHost:host port:0 error:&err];
    
    NSData *address4 = nil;
    NSData *address6 = nil;
    
    for (NSData *address in addresses)
    {
        if (!address4 && [GCDAsyncSocket isIPv4Address:address])
        {
            address4 = address;
        }
        else if (!address6 && [GCDAsyncSocket isIPv6Address:address])
        {
            address6 = address;
        }
    }
    
    NSString *ip;
    
    if (address6) {
        WZLog(@"===ipv6===：%@",[GCDAsyncSocket hostFromAddress:address6]);
        ip = [GCDAsyncSocket hostFromAddress:address6];
    }else {
        WZLog(@"===ipv4===：%@",[GCDAsyncSocket hostFromAddress:address4]);
        ip = [GCDAsyncSocket hostFromAddress:address4];
    }
    
    return ip;
    
}
#pragma mark - getter
/**
 *  socket
 */
- (GCDAsyncSocket *)socket{
    if (!_socket) {
        //1.创建串行队列，队列(queue)中的任务只会顺序执行
        dispatch_queue_t socketQueue = dispatch_queue_create("FirstSerialQueue", DISPATCH_QUEUE_SERIAL);
        
        _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
        _socket.IPv4PreferredOverIPv6 = NO;
    }
    return _socket;
}

/**
 *  socket连接状态
 */
- (BOOL)isConnected{
    
    return self.socket.isConnected;
}

- (NSData *)endDataKey{
    
    return [self.endKey dataUsingEncoding:NSUTF8StringEncoding];
}
@end
