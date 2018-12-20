//
//  WWZApiModel.h
//  WWZSocket
//
//  Created by apple on 2018/8/19.
//

#import <Foundation/Foundation.h>

// @"{\"app\":\"wwz\",\"co\":\"wwz\",\"api\":\"[api]\",\"data\":[param]}\n"
@interface WWZRequestModel : NSObject

@property (nonatomic, copy) NSString *co;
@property (nonatomic, copy) NSString *api;
@property (nonatomic, strong) id data;

- (instancetype)initWithApi:(NSString *)api data:(id)data;
@end
