//
//  WWZTCPSocketClient.h
//  WWZSocket
//
//  Created by wwz on 16/3/2.
//

#import <UIKit/UIKit.h>
@class WWZTCPSocketClient;

// socket连接状态
typedef NS_ENUM(NSUInteger, WWZSocketStatus) {
    WWZSocketStatusNotConnect,
    WWZSocketStatusConnecting,
    WWZSocketStatusConnected,
};

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
@property (nonatomic, copy) NSString *endKeyString;

@property (nonatomic, strong) NSData *endKeyData;

@property (nonatomic, assign, readonly) WWZSocketStatus socketStatus;

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
