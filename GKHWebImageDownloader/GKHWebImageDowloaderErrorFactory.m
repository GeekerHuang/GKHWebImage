//
//  GKHWebImageDowloaderErrorFactory.m
//  GKHWebImage
//
//  Created by huangshuai on 16/10/2.
//  Copyright © 2016年 GKH. All rights reserved.
//

#import "GKHWebImageDowloaderErrorFactory.h"

static NSString *const GKHWebImageDownloaderDomain = @"GKHWebImageDownloaderDomain";

@implementation GKHWebImageDowloaderErrorFactory

- (NSError *)errorWithCompletedErrorCode:(GKHWebImageDownloaderCompletedErrorCode)completedErrorCode code: (NSInteger)code
{
    if (GKHWebImageDownloaderCompletedNone == completedErrorCode) {
        return nil;
    }
    
    NSError *error = nil;
    NSString *domain = GKHWebImageDownloaderDomain;
    
    switch (completedErrorCode) {
        case GKHWebImageDownloaderCompletedNoneRequest:
            error = [NSError errorWithDomain:domain
                                        code:code
                                    userInfo:@{NSLocalizedDescriptionKey : @"Request can't created"}];
            break;
        case GKHWebImageDownloaderCompletedErrorStatusCode:
            error = [NSError errorWithDomain:domain
                                        code:code
                                    userInfo:@{NSLocalizedDescriptionKey : @"StatusCode has problems"}];
            break;
        case GKHWebImageDownloaderCompletedNotHttpProtocol:
            error = [NSError errorWithDomain:domain
                                        code:code
                                    userInfo:@{NSLocalizedDescriptionKey : @"Not http protocol"}];
            break;
        case GKHWebImageDownloaderCompletedImageHasNonePixel:
            error = [NSError errorWithDomain:domain
                                        code:code
                                    userInfo:@{NSLocalizedDescriptionKey : @"Downloaded image has 0 pixels"}];
            break;
        case GKHWebImageDownloaderCompletedImageHasNoneData:
            error = [NSError errorWithDomain:domain code:code userInfo:@{NSLocalizedDescriptionKey : @"Image data is nil"}];
            break;
        case GKHWebImageDownloaderCompletedURLIsNUll:
            error = [NSError errorWithDomain:domain code:code userInfo:@{NSLocalizedDescriptionKey : @"URL is nil"}];
            break;
        default:
            break;
    }
    
    return error;
}

@end
