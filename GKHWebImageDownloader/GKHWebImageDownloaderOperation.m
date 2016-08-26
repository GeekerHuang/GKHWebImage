//
//  GKHWebImageDownloaderOperation.m
//  GKHWebImage
//
//  Created by huangshuai on 16/8/21.
//  Copyright © 2016年 GKH. All rights reserved.
//

#import "GKHWebImageDownloaderOperation.h"

@interface GKHWebImageDownloaderOperation (/*private*/)<NSURLSessionDataDelegate, NSURLSessionTaskDelegate>
{
    dispatch_semaphore_t _semaphore;
}

@property (nonatomic, assign, getter=isCancelled) BOOL cancelled;
@property (nonatomic, assign, getter=isExecuting) BOOL executing;
@property (nonatomic, assign, getter=isFinished) BOOL finished;

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSMutableData *imageData;

@property (nonatomic, strong) NSURLRequest *request;

// This is weak because it is injected by whoever manages this session. If this gets nil-ed out, we won't be able to run
// the task associated with this operation
@property (nonatomic, weak) NSURLSession *unownedSession;

// This is set if we're using not using an injected NSURLSession. We're responsible of invalidating this one
@property (nonatomic, strong) NSURLSession *ownedSession;

@property (nonatomic, assign) GKHWebImageDownloaderOptions options;
@property (nonatomic, copy) GKHWebImageDownloaderProgressBlock progressBlock;
@property (nonatomic, copy) GKHWebImageDownloaderCompletedBlock completedBlock;
@property (nonatomic, copy) GKHWebImageDownloaderCancelBlock cancelBlock;

@end

@implementation GKHWebImageDownloaderOperation

@synthesize cancelled = _cancelled;
@synthesize executing = _executing;
@synthesize finished = _finished;

+ (void)gkhWebImageNetworkThreadEntryPoint:(id)__unused object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"com.network.GKHWebImage"];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

+ (NSThread *)gkhWebImageNetworkRequestThread {
    static NSThread *_networkRequestThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _networkRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(gkhWebImageNetworkThreadEntryPoint:) object:nil];
        [_networkRequestThread start];
    });
    
    return _networkRequestThread;
}

- (instancetype)initWithRequest:(NSURLRequest *)request
                      inSession:(NSURLSession *)session
                        options:(GKHWebImageDownloaderOptions)options
                       progress:(GKHWebImageDownloaderProgressBlock)progressBlock
                      completed:(GKHWebImageDownloaderCompletedBlock)completedBlock
                      cancelled:(GKHWebImageDownloaderCancelBlock)cancelBlock
{
    if(self = [super init]) {
        _request = request;
        _unownedSession = session;
        _options = options;
        _progressBlock = progressBlock;
        _completedBlock = completedBlock;
        _cancelBlock = cancelBlock;
        _semaphore = dispatch_semaphore_create(1);
    }
    
    return self;
}

- (void)start
{
    
}

- (void) cancel
{
    
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse * __nullable cachedResponse))completionHandler
{
    
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler
{
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    
}

#pragma mark - Getter And Setter

- (BOOL)isAsynchronous
{
    return YES;
}

- (BOOL)isCancelled
{
    return _cancelled;
}

- (void)setCancelled:(BOOL)cancelled
{
    [self willChangeValueForKey: @"isCancelled"];
    _cancelled = cancelled;
    [self didChangeValueForKey: @"isCancelled"];
}

- (BOOL)isExecuting
{
    return _executing;
}

- (void)setExecuting:(BOOL)executing
{
    [self willChangeValueForKey: @"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey: @"isExecuting"];
}

- (BOOL)isFinished
{
    return _finished;
}

- (void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey: @"isFinished"];
    _finished = finished;
    [self didChangeValueForKey: @"isFinished"];
}

@end
