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

@interface GKHWebImageDownloaderImageProcessor : NSObject

@property (nonatomic, readonly) unsigned long long receivedLength;
@property (nonatomic, assign) unsigned long long expectedContentLength;
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, assign) BOOL isDecompressImage;

- (void)appendData:(NSData *)other;

- (GKHWebImageDowloaderProgressiveBlock *)progressiveBlock;
- (GKHWebImageDowloaderCompletedBlock *)completedBlock;

+ (GKHWebImageDowloaderCompletedBlock *)cancelBlockWithError:(NSError *)error imageURL:(NSURL *)imageURL;
+ (GKHWebImageDowloaderCompletedBlock *)failureBlockWithError:(NSError *)error imageURL:(NSURL *)imageURL;

@end
