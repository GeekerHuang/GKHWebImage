//
//  GKHWebImageDownloaderUtils.h
//  GKHWebImage
//
//  Created by huangshuai on 16/8/25.
//  Copyright © 2016年 GKH. All rights reserved.
//

#ifndef GKHWebImageDownloaderUtils_h
#define GKHWebImageDownloaderUtils_h

#import <UIKit/UIImage.h>

typedef NS_OPTIONS(NSUInteger, GKHWebImageDownloaderOptions){
    GKHWebImageDownloaderDefault = 1 << 0,
    //    /**
    //     *With this flag,
    //     */
    //    GKHWebImageDownloaderProgressiveDownload = 1 << 0,
    
    /**
     * By default, request prevent the use of NSURLCache. With this flag, NSURLCache
     * is used with default policies.
     */
    GKHWebImageDownloaderUseNSURLCache = 1 << 1,
    
    /**
     * Call completion block with nil image/imageData if the image was read from NSURLCache
     * (to be combined with `GKHWebImageDownloaderUseNSURLCache`).
     */
    GKHWebImageDownloaderIgnoreCachedResponse = 1 << 2,
    
    /**
     * In iOS 4+, continue the download of the image if the app goes to background. This is achieved by asking the system for
     * extra time in background to let the request finish. If the background task expires the operation will be cancelled.
     */
    GKHWebImageDownloaderContinueInBackground = 1 << 3,
    
    /**
     * Handles cookies stored in NSHTTPCookieStore by setting
     * NSMutableURLRequest.HTTPShouldHandleCookies = YES;
     */
    GKHWebImageDownloaderHandleCookies = 1 << 4,
    
    /**
     * Enable to allow untrusted SSL certificates.
     * Useful for testing purposes. Use with caution in production.
     */
    GKHWebImageDownloaderAllowInvalidSSLCertificates = 1 << 5
};

typedef NS_ENUM(NSUInteger, GKHWebImageDownloaderExecutionOrder) {
    
    /**
     * Default value. All download operations will execute in queue style (first-in-first-out).
     */
    GKHWebImageDownloaderFIFOExecutionOrder,
    
    /**
     * All download operations will execute in stack style (last-in-first-out).
     */
    GKHWebImageDownloaderLIFOExecutionOrder
};

typedef NS_ENUM(NSInteger, GKHWebImageOperationQueuePriority) {
    GKHWebImageOperationQueuePriorityVeryLow = -8L,
    GKHWebImageOperationQueuePriorityLow = -4L,
    GKHWebImageOperationQueuePriorityNormal = 0,
    GKHWebImageOperationQueuePriorityHigh = 4,
    GKHWebImageOperationQueuePriorityVeryHigh = 8
};

typedef void(^GKHWebImageDownloaderProgressBlock)(NSUInteger receivedSize, NSUInteger expectedSize);

typedef void(^GKHWebImageDownloaderCompletedBlock)(UIImage *image, NSData *data, NSURL *imageUrl, NSError *error, BOOL isFinished);

typedef void(^GKHWebImageDownloaderCancelBlock)();

typedef NSURLCredential *(^GKHWebImageDownloaderCredential)();

typedef NSDictionary *(^GKHWebImageDownloaderHeadersFilterBlock)(NSURL *imageUrl, NSDictionary *headers);

#endif /* GKHWebImageDownloaderUtils_h */
