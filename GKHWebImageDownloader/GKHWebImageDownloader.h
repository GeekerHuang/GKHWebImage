//
//  GKHWebImageDownloader.h
//  GKHWebImage
//
//  Created by huangshuai on 16/8/21.
//  Copyright © 2016年 GKH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GKHWebImageOperationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class GKHWebImageDowloaderProgressiveObject;
@class GKHWebImageDowloaderCompletedObject;

typedef NS_OPTIONS(NSUInteger, GKHWebImageDownloaderOptions){
    GKHWebImageDownloaderDefault = 1 << 0,

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
    GKHWebImageDownloaderAllowInvalidSSLCertificates = 1 << 5,
    
    /**
    *With this flag, you can display when the image downloading
    */
    GKHWebImageDownloaderProgressiveDowload = 1 << 6,
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

typedef void(^GKHWebImageDownloaderProgressBlock)(GKHWebImageDowloaderProgressiveObject * _Nonnull progressiveState);

typedef void(^GKHWebImageDownloaderCompletedBlock)(GKHWebImageDowloaderCompletedObject * _Nonnull completedState);

typedef NSURLCredential * _Nullable(^GKHWebImageDownloaderCredential)();

typedef NSDictionary * _Nullable(^GKHWebImageDownloaderHeadersFilterBlock)(NSURL *_Nullable imageUrl, NSDictionary * _Nullable headers);

static const float kGKHWebImageTimeoutRequest = 15.0;

/**/
@interface GKHWebImageDowloaderProgressiveObject : NSObject

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

typedef NS_ENUM(NSUInteger, GKHWebImageDownloaderState) {
    
    /**
     *status: download success
     */
    GKHWebImageDownloaderSuccess,
    
    /**
     *status: download failure
     */
    GKHWebImageDownloaderFailure,
    
    /**
     *status: download cancel
     */
    GKHWebImageDownloaderCancel
};

/**/
@interface GKHWebImageDowloaderCompletedObject : NSObject

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

/**
 *Asynchronous downloader dedicated and optimized for image loading
 */
@interface GKHWebImageDownloader : NSObject

/**
 *  Singleton method, returns the shared instance
 *
 *  @return global shared instance of downloader class
 */
+ (GKHWebImageDownloader *)sharedInstance;

/**
 * Decompressing images that are downloaded and cached can improve performance but can consume lot of memory.
 * Defaults to YES. Set this to NO if you are experiencing a crash due to excessive memory consumption.
 */
@property (nonatomic, assign) BOOL isDecompressImage;

/**
 * set the max concurrent amount of downloads in the NSOperartionQueue
 */
@property (nonatomic, assign) NSUInteger maxConcurrentDowloads;

/**
 * Shows the current amount of downloads that still need to be downloaded
 */
@property (nonatomic, readonly, getter=currentDowloadCount) NSUInteger currentDowloadCount;

/**
 *  The timeout value (in seconds) for the download operation. Default: 15.0.
 */
@property (nonatomic, assign) NSTimeInterval dowloadTimeout;

/**
 * Changes download operations execution order. Default value is `GKHWebImageDownloaderFIFOExecutionOrder`.
 */
@property (nonatomic, assign) GKHWebImageDownloaderExecutionOrder executionOrder;

/**
 * This block will be invoked for each downloading image request, returned
 * NSURLCredential will be used as Credential in corresponding HTTP request.
 */
@property (nonatomic, copy) GKHWebImageDownloaderCredential credendial;

/**
 * Set filter to pick headers for downloading image HTTP request.
 *
 * This block will be invoked for each downloading image request, returned
 * NSDictionary will be used as headers in corresponding HTTP request.
 */
@property (nonatomic, copy) GKHWebImageDownloaderHeadersFilterBlock headersFilter;

/**
 * Creates a GKHWebImageDownloader async downloader instance with a given URL
 *
 * The delegate will be informed when the image is finish downloaded or an error has happen.
 *
 *
 * @param url            The URL to the image to download
 * @param completedBlock A block called once the download is completed
 *
 * @return A cancellable GKHWebImageOperationProtocol
 */
- (id<GKHWebImageOperationProtocol>)dowloadImageWithUrl: (NSURL *)url
                                             completion: (GKHWebImageDownloaderCompletedBlock)completionBlock;

/**
 * Creates a GKHWebImageDownloader async downloader instance with a given URL
 *
 * The delegate will be informed when the image is finish downloaded or an error has happen.
 *
 *
 * @param url            The URL to the image to download
 * @param options        The options to be used for this download
 * @param progressBlock  A block called repeatedly while the image is downloading
 * @param completedBlock A block called once the download is completed
 *
 * @return A cancellable GKHWebImageOperationProtocol
 */
- (id<GKHWebImageOperationProtocol>)dowloadImageWithUrl: (NSURL *_Nullable)url
                                                options: (GKHWebImageDownloaderOptions)options
                                               progress: (_Nullable GKHWebImageDownloaderProgressBlock)progressBlock
                                             completion: (_Nullable GKHWebImageDownloaderCompletedBlock)completionBlock;

/**
 * Creates a GKHWebImageDownloader async downloader instance with a given URL
 *
 * The delegate will be informed when the image is finish downloaded or an error has happen.
 *
 *
 * @param url            The URL to the image to download
 * @param options        The options to be used for this download
 * @param operatioPriority represent priority of NSOperation in the NSOperationQueue
 * @param progressBlock  A block called repeatedly while the image is downloading
 * @param completedBlock A block called once the download is completed
 *
 * @return A cancellable GKHWebImageOperationProtocol
 */
- (id<GKHWebImageOperationProtocol>)dowloadImageWithUrl: (NSURL *_Nullable)url
                                                options: (GKHWebImageDownloaderOptions)options
                                       operatioPriority: (NSOperationQueuePriority)operationPriority
                                               progress: (_Nullable GKHWebImageDownloaderProgressBlock)progressBlock
                                             completion: (_Nullable GKHWebImageDownloaderCompletedBlock)completionBlock;


/**
 * Set a value for a HTTP header to be appended to each download HTTP request.
 *
 * @param value The value for the header field. Use `nil` value to remove the header.
 * @param field The name of the header field to set.
 */
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

/**
 * Returns the value of the specified HTTP header field.
 *
 * @return The value associated with the header field field, or `nil` if there is no corresponding header field.
 */
- (NSString *)valueForHTTPHeaderField:(NSString *)field;

/**
 * Sets the download queue suspension state
 */
- (void)setSuspended: (BOOL)isSuspended;

/**
 * Cancels all download operations in the queue
 */
- (void)cancelAllDownloads;

@end

NS_ASSUME_NONNULL_END
