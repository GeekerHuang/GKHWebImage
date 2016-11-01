//
//  GKHWebImageDownloaderOperation.h
//  GKHWebImage
//
//  Created by huangshuai on 16/8/21.
//  Copyright © 2016年 GKH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GKHWebImageOperationProtocol.h"
#import "GKHWebImageDownloader.h"

NS_ASSUME_NONNULL_BEGIN

@interface GKHWebImageDownloaderOperation : NSOperation<GKHWebImageOperationProtocol>

/**
 * Decompressing images that are downloaded and cached can improve performance but can consume lot of memory.
 * Defaults to YES. Set this to NO if you are experiencing a crash due to excessive memory consumption.
 */
@property (nonatomic, assign) BOOL isDecompressImage;

/**
 * The credential used for authentication challenges in `-connection:didReceiveAuthenticationChallenge:`.
 */
@property (nonatomic, strong, nullable) NSURLCredential *credential;

/**
 *  Initializes a `GKHWebImageDownloaderOperation` object
 *
 *  @see GKHWebImageDownloaderOperation
 *
 *  @param request        the URL request
 *  @param session        the URL session in which this operation will run
 *  @param options        downloader options
 *  @param progressBlock  A block invoked in image fetch progress.
                          The block will be invoked in background thread. Pass nil to avoid it.
 *  @param completedBlock A block invoked when image fetch finished.
                          The block will be invoked in background thread. Pass nil to avoid it.
 *
 *  @return the initialized instance
 */
- (instancetype)initWithRequest:(NSURLRequest *)request
                      inSession:(nullable NSURLSession *)session
                        options:(GKHWebImageDownloaderOptions)options
                       progress:(nullable GKHWebImageDownloaderProgressBlock)progressBlock
                      completed:(nullable GKHWebImageDownloaderCompletedBlock)completedBlock
                       NS_DESIGNATED_INITIALIZER;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

@end

NS_ASSUME_NONNULL_END
