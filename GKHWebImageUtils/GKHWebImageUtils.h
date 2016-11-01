//
//  GKHWebImageUtils.h
//  GKHWebImage
//
//  Created by huangshuai on 16/8/26.
//  Copyright © 2016年 GKH. All rights reserved.
//

#ifndef GKHWebImageUtils_h
#define GKHWebImageUtils_h


#define GKHWebImageCreateLock dispatch_semaphore_create(1)
#define GKHWebImageLock(semaphore)  dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
#define GKHWebImageUnLock(semaphore)  dispatch_semaphore_signal(semaphore)


#endif /* GKHWebImageUtils_h */
