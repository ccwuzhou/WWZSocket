//
//  ViewController.m
//  Demo
//
//  Created by wwz on 17/3/6.
//  Copyright © 2017年 tijio. All rights reserved.
//

#import "ViewController.h"
#import "WWZSocket.h"

@interface ViewController ()<WWZTCPSocketDelegate>

@property (nonatomic, strong) WWZTCPSocketClient *tcpSocket;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    _tcpSocket = [[WWZTCPSocketClient alloc] initWithDelegate:self endKey:nil];
    [_tcpSocket connectToHost:@"" onPort:123];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
