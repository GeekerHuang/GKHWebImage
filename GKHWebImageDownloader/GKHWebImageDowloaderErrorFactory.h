//
//  GKHWebImageDowloaderErrorFactory.h
//  GKHWebImage
//
//  Created by huangshuai on 16/10/2.
//  Copyright © 2016年 GKH. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, GKHWebImageDownloaderCompletedErrorCode){
    GKHWebImageDownloaderCompletedNone,
    GKHWebImageDownloaderCompletedNoneRequest,
    GKHWebImageDownloaderCompletedErrorStatusCode,
    GKHWebImageDownloaderCompletedNotHttpProtocol,
    GKHWebImageDownloaderCompletedImageHasNonePixel,
    GKHWebImageDownloaderCompletedImageHasNoneData,
    GKHWebImageDownloaderCompletedURLIsNUll
};

@interface GKHWebImageDowloaderErrorFactory : NSObject

+ (NSError *)errorWithCompletedErrorCode:(GKHWebImageDownloaderCompletedErrorCode)completedErrorCode code: (NSInteger)code;

@end
