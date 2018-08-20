//
//  WWZResponseModel.m
//  WWZSocket
//
//  Created by apple on 2018/8/20.
//

#import "WWZResponseModel.h"

NSString *const NOTI_PREFIX = @"wwz";

@implementation WWZResponseModel

- (instancetype)initWithResult:(id)result{
    if (self = [super init]) {
        self.retcode = [result[@"retcode"] respondsToSelector:@selector(intValue)] ? [result[@"retcode"] intValue] : -1;
        self.message = [result[@"message"] isKindOfClass:[NSString class]] ? result[@"message"] : @"";
        self.co = result[@"co"];
        self.api = [result[@"api"] isKindOfClass:[NSString class]] ? result[@"api"] : @"";
        self.data = result[@"data"];
    }
    return self;
}
@end
