//
//  GKHWebImageDownloaderImageProcessor.h
//  GKHWebImage
//
//  Created by huangshuai on 16/9/19.
//  Copyright © 2016年 GKH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GKHWebImageDownloader.h"

@interface GKHWebImageDownloaderImageProcessor : NSObject

@property (nonatomic, readonly) unsigned long long receivedLength;
@property (nonatomic, assign) unsigned long long expectedContentLength;
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, assign) BOOL isDecompressImage;

- (void)appendData:(NSData *)other;

- (GKHWebImageDowloaderProgressiveObject *)progressiveBlock;
- (GKHWebImageDowloaderCompletedObject *)completedBlock;

+ (GKHWebImageDowloaderCompletedObject *)cancelBlockWithError:(NSError *)error imageURL:(NSURL *)imageURL;
+ (GKHWebImageDowloaderCompletedObject *)failureBlockWithError:(NSError *)error imageURL:(NSURL *)imageURL;

@end
