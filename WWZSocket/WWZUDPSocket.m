//
//  WWZUDPSocket.m
//  wwz
//
//  Created by wwz on 16/6/18.
//  Copyright © 2016年 cn.szwwz. All rights reserved.
//

#import "WWZUDPSocket.h"

#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>

// ...表示宏定义的可变参数
// __VA_ARGS__:表示函数里面的可变参数
#ifdef WZDEBUG // 调试

#define WZLog(fmt, ...) NSLog((@"%s " fmt), __PRETTY_FUNCTION__, ##__VA_ARGS__)

#else // 发布

#define WZLog(...)

#endif

@interface WWZUDPSocket ()<GCDAsyncUdpSocketDelegate>

@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;

@end


@implementation WWZUDPSocket

+ (instancetype)updSocketWithPort:(uint16_t)port delegate:(id<WZUDPSocketDelegate>)delegate{
    
    return [[self alloc] initWithPort:port delegate:delegate];
}

- (instancetype)initWithPort:(uint16_t)port delegate:(id<WZUDPSocketDelegate>)delegate
{
    self = [super init];
    if (self) {
        
        self.delegate = delegate;
        NSError *error = nil;
        if (![self.udpSocket bindToPort:port error:&error])
            WZLog(@"error bind port: %@", [error localizedDescription]);
        
        if (![self.udpSocket enableBroadcast:YES error:&error])
            WZLog(@"Error enableBroadcast: %@", [error localizedDescription]);
        
        if (![self.udpSocket beginReceiving:&error])
            WZLog(@"Error receiving: %@", [error localizedDescription]);
        
    }
    return self;
}
/**
 *  广播数据
 */
- (void)broadcastMessage:(NSString *)message toPort:(uint16_t)port{
    [self sendMessage:message toHost:@"255.255.255.255" port:port];
}
/**
 *  往指定ip发送数据
 *
 *  @param message message
 *  @param host    ip
 */
- (void)sendMessage:(NSString *)message toHost:(NSString *)host port:(uint16_t)port{
    WZLog(@"%@", message);

    [self.udpSocket sendData:[message dataUsingEncoding:NSUTF8StringEncoding] toHost:host port:port withTimeout:-1 tag:0];
}
/**
 *  关闭socket
 */
- (void)close{
    [self.udpSocket close];
    _udpSocket = nil;
}
#pragma mark - GCDAsyncUdpSocketDelegate
/**
 *  数据已发出
 */
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag{
    
//    WZLog();
}
/**
 *  updSocket关闭
 */
- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error{
    
    WZLog(@"error %@", error);
}
/**
 *  收到upd数据
 */
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext{
    
    NSString *host = [GCDAsyncUdpSocket hostFromAddress:address];
    
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    WZLog(@"+++++%@+++++", msg);
    
    if ([self.delegate respondsToSelector:@selector(udpSocket:didReceiveMessage:fromHost:)]) {
        [self.delegate udpSocket:self didReceiveMessage:msg fromHost:host];
    }
}

#pragma mark - updSocket
- (GCDAsyncUdpSocket *)udpSocket{
    if (!_udpSocket) {
        _udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [_udpSocket setIPv6Enabled:YES];
    }
    return _udpSocket;
}

@end
