//
//  GKHWebImageDowloaderProgressiveBlock.h
//  GKHWebImage
//
//  Created by huangshuai on 16/9/20.
//  Copyright © 2016年 GKH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIImage.h>

@interface GKHWebImageDowloaderProgressiveBlock : NSObject

@property (nonatomic, readonly) unsigned long long receivedSize;
@property (nonatomic, readonly) unsigned long long expectedContentLength;
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) NSData *imageData;
@property (nonatomic, readonly) NSURL *imageURL;

- (instancetype)initWithReceivedSize:(unsigned long long)receivedSize
               expectedContentLength:(unsigned long long)expectedContentLength
                               image:(UIImage *)image
                           imageData:(NSData *)imageData
                            imageURL:(NSURL *)imageURL;

@end
