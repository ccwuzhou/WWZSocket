//
//  WWZUDPSocket.h
//  wwz
//
//  Created by wwz on 16/6/18.
//  Copyright © 2016年 cn.szwwz. All rights reserved.
//

#import <Foundation/Foundation.h>

// 添加打印日志
//#define WZDEBUG

@class WWZUDPSocket;

@protocol WZUDPSocketDelegate <NSObject>

@optional

/**
 *  收到数据回调
 *
 *  @param udpSocket udpSocket
 *  @param message   message
 *  @param host      ip
 */
- (void)udpSocket:(WWZUDPSocket *)udpSocket didReceiveMessage:(NSString *)message fromHost:(NSString *)host;

@end


@interface WWZUDPSocket : NSObject

@property (nonatomic, weak) id<WZUDPSocketDelegate> delegate;

+ (instancetype)updSocketWithPort:(uint16_t)port delegate:(id<WZUDPSocketDelegate>)delegate;

/**
 *  广播数据
 */
- (void)broadcastMessage:(NSString *)message toPort:(uint16_t)port;

/**
 *  往指定ip发送数据
 *
 *  @param message message
 *  @param host    ip
 */
- (void)sendMessage:(NSString *)message toHost:(NSString *)host port:(uint16_t)port;

/**
 *  关闭socket
 */
- (void)close;

@end
