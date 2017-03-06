//
//  WWZTCPSocketClient.h
//  SmartHome_iPad
//
//  Created by wwz on 16/3/2.
//  Copyright © 2016年 zgkjd. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const ERROR_NOTI_NAME;// 收到错误数据通知

@class WWZTCPSocketClient;

@protocol WWZTCPSocketDelegate <NSObject>

@optional
/**
 *  socket连接成功回调
 */
- (void)tcpSocket:(WWZTCPSocketClient *)tcpSocket didConnectToHost:(NSString *)host port:(uint16_t)port;

/**
 *  socket连接失败回调
 */
- (void)tcpSocket:(WWZTCPSocketClient *)tcpSocket didDisconnectWithError:(NSError *)error;

/**
 *  socket收到数据回调
 */
- (void)tcpSocket:(WWZTCPSocketClient *)tcpSocket didReadResult:(id)result;

@end


@interface WWZTCPSocketClient : NSObject

@property (nonatomic, weak) id<WWZTCPSocketDelegate> tcpDelegate;

/**
 *  读取结束字符
 */
@property (nonatomic, copy) NSString *endKey;

/**
 *  正在连接中
 */
@property (nonatomic, assign, readonly) BOOL isConnecting;

/**
 *  socket连接状态
 */
@property (nonatomic, assign, readonly) BOOL isConnected;

/**
 *  初始化
 *  @param endDataKey 读取结束字符, default is nill
 */
- (instancetype)initWithDelegate:(id<WWZTCPSocketDelegate>)delegate endKey:(NSString *)endKey;

/**
 *  connect socket
 */
- (void)connectToHost:(NSString*)host onPort:(uint16_t)port;

/**
 *  disconnect socket
 */
- (void)disconnectSocket;

/**
 *  send data to socket
 */
- (void)sendDataToSocketWithData:(NSData *)data;
- (void)sendDataToSocketWithString:(NSString *)string;

@end
