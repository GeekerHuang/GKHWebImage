//
//  GKHWebImageDownloaderOperation.m
//  GKHWebImage
//
//  Created by huangshuai on 16/8/21.
//  Copyright © 2016年 GKH. All rights reserved.
//

#import "GKHWebImageDownloaderOperation.h"
#import "GKHWebImageUtils.h"
#import <UIKit/UIApplication.h>

static NSString *const GKHWebImageDownloaderDomain = @"GKHWebImageDownloaderDomain";

@interface GKHWebImageDownloaderOperation (/*private*/)<NSURLSessionDataDelegate, NSURLSessionTaskDelegate>
{
    dispatch_semaphore_t _semaphore;
}

@property (nonatomic, assign, getter=isCancelled) BOOL cancelled;
@property (nonatomic, assign, getter=isExecuting) BOOL executing;
@property (nonatomic, assign, getter=isFinished) BOOL finished;

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSMutableData *imageData;
@property (nonatomic, assign) long long expectedContentLength;
@property (nonatomic, assign) BOOL responseFromCache;

@property (nonatomic, strong) NSURLRequest *request;

// This is weak because it is injected by whoever manages this session. If this gets nil-ed out, we won't be able to run
// the task associated with this operation
@property (nonatomic, weak) NSURLSession *unownedSession;

// This is set if we're using not using an injected NSURLSession. We're responsible of invalidating this one
@property (nonatomic, strong) NSURLSession *ownedSession;

@property (nonatomic, assign) GKHWebImageDownloaderOptions options;
@property (nonatomic, copy) GKHWebImageDownloaderProgressBlock progressBlock;
@property (nonatomic, copy) GKHWebImageDownloaderCompletedBlock completedBlock;

@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskId;

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
{
    if(self = [super init]) {
        _request = request;
        _unownedSession = session;
        _options = options;
        _progressBlock = [progressBlock copy];
        _completedBlock = [completedBlock copy];
        _isDecompressImage = YES;
        _responseFromCache = YES;
        _executing = NO;
        _finished = NO;
        _cancelled = NO;
        _semaphore = dispatch_semaphore_create(1);
    }
    
    return self;
}

- (void)start
{
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    if(self.isCancelled) {
        [self done];
        dispatch_semaphore_signal(_semaphore);
        return;
    }
    
    if ([self shouldContinueWhenAppEntersBackground]) {
        __weak __typeof__ (self) wself = self;
        self.backgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            __strong __typeof (wself) sself = wself;
            
            if (sself) {
                [sself cancel];
                
                [[UIApplication sharedApplication] endBackgroundTask:sself.backgroundTaskId];
                sself.backgroundTaskId = UIBackgroundTaskInvalid;
            }
        }];
    }

    NSURLSession *session = _unownedSession;
    if(!session) {
        if (!_ownedSession) {
            NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            sessionConfig.timeoutIntervalForRequest = kGKHWebImageTimeoutRequest;
            
            self.ownedSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate: self delegateQueue: nil];
        }
        
        session = _ownedSession;
    }
    
    if(!_dataTask) {
        self.dataTask = [session dataTaskWithRequest:_request];
        [_dataTask resume];
        self.executing = YES;
    }
    
    if (!_dataTask) {
        if(!_completedBlock) {
            NSError *error = [NSError errorWithDomain: GKHWebImageDownloaderDomain code:0 userInfo: @{NSLocalizedDescriptionKey : @"Data task can't be initialized"}];
            _completedBlock(nil, nil, nil, GKHWebImageDownloaderFinshed, error);
            [self done];
        }
    }
    
    if (self.backgroundTaskId != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskId];
        self.backgroundTaskId = UIBackgroundTaskInvalid;
    }

    dispatch_semaphore_signal(_semaphore);
}

- (void)cancel
{
    [self performSelector:@selector(cancelDownloaderRequest)
                 onThread:[[self class]gkhWebImageNetworkRequestThread]
               withObject:nil
            waitUntilDone:NO];
}

- (void)cancelDownloaderRequest
{
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    
    if (_finished) {
        dispatch_semaphore_signal(_semaphore);
        return;
    }
    
    [super cancel];
    
    if (_completedBlock) {
        _completedBlock(nil, nil, nil, GKHWebImageDownloaderCancelled, nil);
    }
    
    if (_dataTask) {
        [_dataTask cancel];
    }
    
    [self done];
    dispatch_semaphore_signal(_semaphore);
}

- (void)done
{
    if (_finished) {
        return;
    }
    
    if (_executing) {
        self.executing = NO;
    }
    
    if (!_finished) {
        self.finished = YES;
    }
    [self reset];
}

- (void)reset
{
    self.progressBlock = nil;
    self.completedBlock = nil;
    self.request = nil;
    self.imageData = nil;
    self.dataTask = nil;
    self.credential = nil;
    
    if(_ownedSession) {
        [_ownedSession invalidateAndCancel];
        self.ownedSession = nil;
    }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    @autoreleasepool {
        dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
        if (_cancelled) {
            [self done];
            dispatch_semaphore_signal(_semaphore);
            return;
        }
        
        if ([response respondsToSelector:@selector(statusCode)]
            && (([(NSHTTPURLResponse *)response statusCode] < 400) && ([(NSHTTPURLResponse *)response statusCode] != 304))) {
            NSInteger statusCode = [((NSHTTPURLResponse *)response) statusCode];
            if (statusCode < 400 && statusCode != 304) {
                long long expectedContentLength = response.expectedContentLength > 0 ? response.expectedContentLength : 0;
                self.expectedContentLength = expectedContentLength;
                self.imageData = [[NSMutableData alloc] initWithCapacity: _expectedContentLength];
                if(_progressBlock) {
                    _progressBlock(0, _expectedContentLength);
                }
            } else {
                
                [_dataTask cancel];
                
                if (_completedBlock) {
                    NSError *error = [NSError errorWithDomain:GKHWebImageDownloaderDomain
                                                         code:[((NSHTTPURLResponse *)response) statusCode]
                                                     userInfo:@{NSLocalizedDescriptionKey : @"StatusCode has problems"}];
                    _completedBlock(nil, nil, nil, GKHWebImageDownloaderFinshed, error);
                }
                [self done];
            }
        } else {
            if (_completedBlock) {
                NSError *error = [NSError errorWithDomain:GKHWebImageDownloaderDomain
                                                     code:0
                                                 userInfo:@{NSLocalizedDescriptionKey : @"Not http protocol"}];
                _completedBlock(nil, nil, nil, GKHWebImageDownloaderFinshed, error);
            }
            [self done];
        }
        dispatch_semaphore_signal(_semaphore);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    @autoreleasepool {
        dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
        if (_cancelled) {
            [self done];
            dispatch_semaphore_signal(_semaphore);
            return;
        }
        [_imageData appendData: data];
        
        dispatch_semaphore_signal(_semaphore);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse * __nullable cachedResponse))completionHandler
{
    @autoreleasepool {
        dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
        if (_cancelled) {
            [self done];
            dispatch_semaphore_signal(_semaphore);
            return;
        }
        
        self.responseFromCache = NO;
        
        if (_request.cachePolicy == NSURLRequestReloadIgnoringLocalCacheData) {
            proposedResponse = nil;
        }
        dispatch_semaphore_signal(_semaphore);
        
        completionHandler(proposedResponse);
    }
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler
{
    @autoreleasepool {
        dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
        if (_cancelled) {
            [self done];
            dispatch_semaphore_signal(_semaphore);
            return;
        }
        
        NSURLSessionAuthChallengeDisposition completionDispostion = NSURLSessionAuthChallengePerformDefaultHandling;
        NSURLCredential *completionCredential = nil;
        
        if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            if (![self shouldAllowInvalidSSLCertificates]) {
                completionDispostion = NSURLSessionAuthChallengePerformDefaultHandling;
            } else {
                completionCredential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                completionDispostion = NSURLSessionAuthChallengeUseCredential;
            }
        } else {
            if(challenge.previousFailureCount == 0) {
                completionCredential = _credential;
                completionDispostion = NSURLSessionAuthChallengeUseCredential;
            } else {
                completionDispostion = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
            }
        }
        
        dispatch_semaphore_signal(_semaphore);
        
        completionHandler(completionDispostion, completionCredential);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    @autoreleasepool {
        dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
        if (_cancelled) {
            [self done];
            dispatch_semaphore_signal(_semaphore);
            return;
        }
        
        dispatch_semaphore_signal(_semaphore);
    }
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
    if (_cancelled != cancelled) {
        [self willChangeValueForKey:@"isCancelled"];
        _cancelled = cancelled;
        [self didChangeValueForKey:@"isCancelled"];
    }
}

- (BOOL)isExecuting
{
    return _executing;
}

- (void)setExecuting:(BOOL)executing
{
    if (_executing != executing) {
        [self willChangeValueForKey:@"isExecuting"];
        _executing = executing;
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (BOOL)isFinished
{
    return _finished;
}

- (void)setFinished:(BOOL)finished
{
    if (_finished != finished) {
        [self willChangeValueForKey:@"isFinished"];
        _finished = finished;
        [self didChangeValueForKey:@"isFinished"];
    }
}

- (BOOL)shouldAllowInvalidSSLCertificates
{
    return _options & GKHWebImageDownloaderAllowInvalidSSLCertificates;
}

- (BOOL)shouldContinueWhenAppEntersBackground
{
    return _options & GKHWebImageDownloaderContinueInBackground;
}

@end
