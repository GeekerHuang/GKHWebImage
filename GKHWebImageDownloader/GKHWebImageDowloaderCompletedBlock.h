//
//  GKHWebImageDowloaderCompletedBlock.h
//  GKHWebImage
//
//  Created by huangshuai on 16/9/20.
//  Copyright © 2016年 GKH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIImage.h>

typedef NS_ENUM(NSUInteger, GKHWebImageDownloaderState) {
    
    /**
     *
     */
    GKHWebImageDownloaderSuccess,
    
    /**
     *
     */
    GKHWebImageDownloaderFailure,
    
    /**
     *
     */
    GKHWebImageDownloaderCancel
};

@interface GKHWebImageDowloaderCompletedBlock : NSObject

@property (nonatomic, readonly) unsigned long long receivedSize;
@property (nonatomic, readonly) unsigned long long expectedContentLength;
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) NSData *imageData;
@property (nonatomic, readonly) NSURL *imageURL;
@property (nonatomic, readonly) GKHWebImageDownloaderState state;
@property (nonatomic, readonly) NSError *error;

- (instancetype)initWithReceivedSize:(unsigned long long)receivedSize
               expectedContentLength:(unsigned long long)expectedContentLength
                               image:(UIImage *)image
                           imageData:(NSData *)imageData
                            imageURL:(NSURL *)imageURL
                               state:(GKHWebImageDownloaderState)state
                               error:(NSError *)error;

@end
