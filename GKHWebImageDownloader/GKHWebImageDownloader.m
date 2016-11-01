//
//  GKHWebImageDownloader.m
//  GKHWebImage
//
//  Created by huangshuai on 16/8/21.
//  Copyright © 2016年 GKH. All rights reserved.
//

#import "GKHWebImageDownloader.h"
#import "GKHWebImageUtils.h"
#import "GKHWebImageDownloaderOperation.h"
#import "GKHWebImageDowloaderErrorFactory.h"
#import "GKHWebImageDownloaderImageProcessor.h"

@implementation GKHWebImageDowloaderProgressiveObject

- (instancetype)initWithReceivedSize:(unsigned long long)receivedSize
               expectedContentLength:(unsigned long long)expectedContentLength
                               image:(UIImage *)image
                           imageData:(NSData *)imageData
                            imageURL:(NSURL *)imageURL
{
    if (self = [super init]) {
        _receivedSize = receivedSize;
        _expectedContentLength = expectedContentLength;
        _image = image;
        _imageData = imageData;
        _imageURL = imageURL;
    }
    
    return self;
}

@end

@implementation GKHWebImageDowloaderCompletedObject

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


typedef void(^GKHWebImageNoParamsBlock)();
static NSString *const downloaderProgressCallBackKey = @"GKHProgress";
static NSString *const downloaderCompletionCallBackKey = @"GKHCompletion";

@interface GKHWebImageDownloader (/*private*/)<NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSOperationQueue *downloadQueue;
@property (nonatomic, weak) NSOperation *lastAddedOperation;
@property (nonatomic, strong) NSMutableDictionary *HTTPHeaders;
@property (nonatomic,strong) NSMutableDictionary *URLCallBacks;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation GKHWebImageDownloader

+ (GKHWebImageDownloader *)sharedInstance
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (instancetype)init
{
    if(self = [super init]) {
        _downloadQueue = [NSOperationQueue new];
        _downloadQueue.maxConcurrentOperationCount = 6;
        _isDecompressImage = YES;
#ifdef GKH_WEBP
        _HTTPHeaders = [@{@"Accept": @"image/webp,image/*;q=0.8"} mutableCopy];
#else
        _HTTPHeaders = [@{@"Accept": @"image/*;q=0.8"} mutableCopy];
#endif
        _URLCallBacks = [NSMutableDictionary new];
        
        NSURLSessionConfiguration *defaultConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        defaultConfig.timeoutIntervalForRequest = kGKHWebImageTimeoutRequest;
        
        _session = [NSURLSession sessionWithConfiguration:defaultConfig
                                                 delegate:self
                                            delegateQueue:nil];
        
        _queue = dispatch_queue_create("com.GKHWebImage.dowloader", DISPATCH_QUEUE_CONCURRENT);
    }
    
    return self;
}

#pragma mark - Public Method

- (id<GKHWebImageOperationProtocol>)dowloadImageWithUrl: (NSURL *)url
                                             completion: (GKHWebImageDownloaderCompletedBlock)completionBlock
{
    return [self dowloadImageWithUrl:url
                             options:GKHWebImageDownloaderDefault
                    operatioPriority:NSOperationQueuePriorityNormal
                            progress:nil
                          completion:completionBlock];
}

- (id<GKHWebImageOperationProtocol>)dowloadImageWithUrl: (NSURL *)url
                                                options: (GKHWebImageDownloaderOptions)options
                                               progress: (GKHWebImageDownloaderProgressBlock)progressBlock
                                              completion: (GKHWebImageDownloaderCompletedBlock)completionBlock
{
    return [self dowloadImageWithUrl:url
                             options:options
                    operatioPriority:NSOperationQueuePriorityNormal
                            progress:progressBlock
                          completion:completionBlock];
}

- (id<GKHWebImageOperationProtocol>)dowloadImageWithUrl: (NSURL *)url
                                                options: (GKHWebImageDownloaderOptions)options
                                       operatioPriority: (NSOperationQueuePriority)operationPriority
                                               progress: (GKHWebImageDownloaderProgressBlock)progressBlock
                                              completion: (GKHWebImageDownloaderCompletedBlock)completionBlock
{
    __block id<GKHWebImageOperationProtocol> operationProtocol = nil;
    __weak __typeof(self) wself = self;
    
    [self addProgressBlock:progressBlock completionBlock:completionBlock forUrl:url createBlock:^{
        
        NSTimeInterval dowloadTimeout = wself.dowloadTimeout;
        if (dowloadTimeout == 0) {
            dowloadTimeout = kGKHWebImageTimeoutRequest;
        }
        NSURLRequestCachePolicy cachePolicy = options & GKHWebImageDownloaderUseNSURLCache ? NSURLRequestUseProtocolCachePolicy : NSURLRequestReloadIgnoringLocalCacheData;
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: url cachePolicy: cachePolicy timeoutInterval: dowloadTimeout];
        
        GKHWebImageDownloaderOperation *downloaderOperation =[[GKHWebImageDownloaderOperation alloc] initWithRequest:request inSession: wself.session options:options progress:^(GKHWebImageDowloaderProgressiveObject *progressiveState) {
            GKHWebImageDownloader *sself = wself;
            if (sself) {
                __block NSMutableArray *callBacksForUrl = nil;
                dispatch_barrier_sync(sself.queue, ^{
                    callBacksForUrl = [sself.URLCallBacks[url] copy];
                });
                
                [callBacksForUrl enumerateObjectsUsingBlock:^(NSMutableDictionary * _Nonnull callBack, NSUInteger idx, BOOL * _Nonnull stop) {
                    GKHWebImageDownloaderProgressBlock progressBlock = callBack[downloaderProgressCallBackKey];
                    if (progressBlock) {
                        progressBlock(progressiveState);
                    }
                }];
            }
        } completed:^(GKHWebImageDowloaderCompletedObject *completedState) {
            GKHWebImageDownloader *sself = wself;
            if (sself) {
                BOOL success = (GKHWebImageDownloaderSuccess == completedState.state);
                BOOL failure = (GKHWebImageDownloaderFailure == completedState.state);
                BOOL cancel = (GKHWebImageDownloaderCancel == completedState.state);
                if (success || failure) {
                    __block NSMutableArray *callBacksForUrl = nil;
                    dispatch_barrier_sync(sself.queue, ^{
                        callBacksForUrl = [sself.URLCallBacks[url] copy];
                        [sself.URLCallBacks removeObjectForKey: url];
                    });
                    
                    [callBacksForUrl enumerateObjectsUsingBlock:^(NSMutableDictionary * _Nonnull callBack, NSUInteger idx, BOOL * _Nonnull stop) {
                        GKHWebImageDownloaderCompletedBlock completionBlock = callBack[downloaderCompletionCallBackKey];
                        if (completionBlock) {
                            completionBlock(completedState);
                        }
                    }];
                } else if(cancel) {
                    dispatch_barrier_async(sself.queue, ^{
                        [sself.URLCallBacks removeObjectForKey: url];
                    });
                }
        }
            
        downloaderOperation.credential = wself.credendial();
        downloaderOperation.queuePriority = operationPriority;
        downloaderOperation.isDecompressImage = wself.isDecompressImage;
            
        [wself.downloadQueue addOperation:downloaderOperation];
        if (wself.executionOrder == GKHWebImageDownloaderLIFOExecutionOrder) {
                // Emulate LIFO execution order by systematically adding new operations as last operation's dependency
                [wself.lastAddedOperation addDependency:downloaderOperation];
                wself.lastAddedOperation = downloaderOperation;
        }

        }];
        
    }];
    
    return operationProtocol;
}

- (void)addProgressBlock:(GKHWebImageDownloaderProgressBlock)progressBlock
         completionBlock:(GKHWebImageDownloaderCompletedBlock)completionBlock
                  forUrl:(NSURL *)url
             createBlock:(GKHWebImageNoParamsBlock)createBlock
{
    if (nil == url) {
        if(nil != completionBlock) {
            NSError *error = [GKHWebImageDowloaderErrorFactory errorWithCompletedErrorType:GKHWebImageDownloaderCompletedURLIsNUll errorCode:GKHWebImageDownloaderDefaultCode];
            GKHWebImageDowloaderCompletedObject *completedBlockObject = [GKHWebImageDownloaderImageProcessor failureBlockWithError:error imageURL:url];
            completionBlock(completedBlockObject);
        }
    }
    
    dispatch_barrier_sync(_queue, ^{
        BOOL isFirst = NO;
        if(!_URLCallBacks[url]) {
            _URLCallBacks[url] = [NSMutableArray new];
            isFirst = YES;
        }
        
        BOOL isChange = YES;
        NSMutableArray *callBacksForURL = _URLCallBacks[url];
        NSMutableDictionary *callBacks = [NSMutableDictionary new];
        if (nil != progressBlock) {
            callBacks[downloaderProgressCallBackKey] = [progressBlock copy];
        }
        
        if (nil != completionBlock) {
            callBacks[downloaderCompletionCallBackKey] = [completionBlock copy];
        }
        
        if (callBacks.count > 0) {
            [callBacksForURL addObject: callBacks];
        } else {
            isChange = NO;
        }
        
        if(isChange) {
            _URLCallBacks[url] = callBacksForURL; 
        }
        
        if (isFirst) {
            createBlock();
        }
    });
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
    if (value) {
        _HTTPHeaders[field] = value;
    } else {
        [_HTTPHeaders removeObjectForKey: field];
    }
}

- (NSString *)valueForHTTPHeaderField:(NSString *)field
{
    return _HTTPHeaders[field];
}

- (NSUInteger)currentDowloadCount
{
    return _downloadQueue.operationCount;
}

- (void)setMaxConcurrentDowloads:(NSUInteger)maxConcurrentDowloads
{
    _downloadQueue.maxConcurrentOperationCount = maxConcurrentDowloads;
}

- (void)setSuspended:(BOOL)isSuspended
{
    _downloadQueue.suspended = isSuspended;
}

- (void)cancelAllDownloads
{
    [_downloadQueue cancelAllOperations];
}

@end
