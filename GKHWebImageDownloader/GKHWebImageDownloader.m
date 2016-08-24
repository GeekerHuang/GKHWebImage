//
//  GKHWebImageDownloader.m
//  GKHWebImage
//
//  Created by huangshuai on 16/8/21.
//  Copyright © 2016年 GKH. All rights reserved.
//

#import "GKHWebImageDownloader.h"

@implementation GKHWebImageDownloader

+ (GKHWebImageDownloader *)sharedInstance
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (instancetype)init
{
    if(self = [super init]) {
        
    }
    
    return self;
}

@end
