//
//  WWZResponseModel.h
//  WWZSocket
//
//  Created by apple on 2018/8/20.
//

#import <Foundation/Foundation.h>

extern NSString *const NOTI_PREFIX;// 通知前缀

@interface WWZResponseModel : NSObject

@property (nonatomic, assign) int retcode;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *co;
@property (nonatomic, copy) NSString *api;
@property (nonatomic, strong) id data;

- (instancetype)initWithResult:(id)result;

@end
