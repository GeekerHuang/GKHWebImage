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
    GKHWebImageDownloaderCompletedURLIsNUll,
    GKHWebImageDownloaderCompletedCacheError
};

static const NSInteger GKHWebImageDownloaderDefaultCode = 0;

@interface GKHWebImageDowloaderErrorFactory : NSObject

+ (NSError *)errorWithCompletedErrorType:(GKHWebImageDownloaderCompletedErrorCode)completedErrorCode errorCode: (NSInteger)code;


@end
