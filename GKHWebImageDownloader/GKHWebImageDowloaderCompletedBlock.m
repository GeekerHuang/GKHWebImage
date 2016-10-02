//
//  GKHWebImageDowloaderCompletedBlock.m
//  GKHWebImage
//
//  Created by huangshuai on 16/9/20.
//  Copyright © 2016年 GKH. All rights reserved.
//

#import "GKHWebImageDowloaderCompletedBlock.h"

@implementation GKHWebImageDowloaderCompletedBlock

- (instancetype)initWithReceivedSize:(unsigned long long)receivedSize
               expectedContentLength:(unsigned long long)expectedContentLength
                               image:(UIImage *)image
                           imageData:(NSData *)imageData
                            imageURL:(NSURL *)imageURL
                               state:(GKHWebImageDownloaderState)state
                               error:(NSError *)error
{
    if (self = [super init]) {
        _receivedSize = receivedSize;
        _expectedContentLength = expectedContentLength;
        _image = image;
        _imageData = imageData;
        _imageURL = imageURL;
        _state = state;
        _error = error;
    }
    
    return self;
}

@end
