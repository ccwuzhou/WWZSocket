//
//  WWZApiModel.m
//  WWZSocket
//
//  Created by apple on 2018/8/19.
//

#import "WWZRequestModel.h"

@implementation WWZRequestModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _co = @"orange";
    }
    return self;
}

- (instancetype)initWithApi:(NSString *)api data:(id)data{
    if (self = [self init]) {
        self.api = api;
        self.data = data;
    }
    return self;
}

@end
