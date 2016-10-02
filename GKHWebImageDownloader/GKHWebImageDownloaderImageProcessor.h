//
//  GKHWebImageDownloaderImageProcessor.h
//  GKHWebImage
//
//  Created by huangshuai on 16/9/19.
//  Copyright © 2016年 GKH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GKHWebImageDowloaderProgressiveBlock.h"
#import "GKHWebImageDowloaderCompletedBlock.h"

static const NSInteger GKHWebImageDownloaderDefaultCode = 0;

@interface GKHWebImageDownloaderImageProcessor : NSObject

@property (nonatomic, assign) unsigned long long expectedContentLength;
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, assign) BOOL isDecompressImage;
- (void)appendData:(NSData *)other;

- (GKHWebImageDowloaderProgressiveBlock *)progressiveBlock;
- (GKHWebImageDowloaderCompletedBlock *)completedBlock;
- (GKHWebImageDowloaderCompletedBlock *)completedBlockWithError:(NSError *)error state:(GKHWebImageDownloaderState)state;
+ (GKHWebImageDowloaderCompletedBlock *)completedBlockWithError:(NSError *)error state:(GKHWebImageDownloaderState)state;

@end
