//
//  GKHWebImageDownloaderImageProcessor.m
//  GKHWebImage
//
//  Created by huangshuai on 16/9/19.
//  Copyright © 2016年 GKH. All rights reserved.
//

#import "GKHWebImageDownloaderImageProcessor.h"
#import <ImageIO/ImageIO.h>
#import "GKHWebImageDecode.h"
#import "GKHWebImageDowloaderErrorFactory.h"

FOUNDATION_STATIC_INLINE UIImageOrientation orientationFromPropertyValue(NSInteger value) {
    switch (value) {
        case 1:
            return UIImageOrientationUp;
        case 3:
            return UIImageOrientationDown;
        case 8:
            return UIImageOrientationLeft;
        case 6:
            return UIImageOrientationRight;
        case 2:
            return UIImageOrientationUpMirrored;
        case 4:
            return UIImageOrientationDownMirrored;
        case 5:
            return UIImageOrientationLeftMirrored;
        case 7:
            return UIImageOrientationRightMirrored;
        default:
            return UIImageOrientationUp;
    }
}

@interface GKHWebImageDownloaderImageProcessor (/*private*/)

@property (nonatomic, assign) UIImageOrientation orientation;
@property (nonatomic, assign) NSUInteger width;
@property (nonatomic, assign) NSUInteger height;
@property (nonatomic, strong) NSMutableData *imageData;

@end

@implementation GKHWebImageDownloaderImageProcessor

- (instancetype)init
{
    if (self = [super init]) {
        _isDecompressImage = YES;
    }
    
    return self;
}

- (void)appendData:(NSData *)other
{
    if (other.length <= 0) {
        return;
    }
    
    [_imageData appendData:other];
}

- (void)setExpectedContentLength:(unsigned long long)expectedContentLength
{
    _expectedContentLength = expectedContentLength;
    [self setUpImageData];
}

- (unsigned long long)receivedLength
{
    return _imageData.length;
}

- (void)setUpImageData
{
    _imageData = [[NSMutableData alloc] initWithCapacity:_expectedContentLength];
}

- (void)setImagePropertyValueWithImageSource:(CGImageSourceRef)imageSource
{
    if (_width + _height == 0) {
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
        if (NULL != properties) {
            NSInteger orientationValue = -1;
            CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
            if (NULL != val)
                CFNumberGetValue(val, kCFNumberLongType, &_height);
            val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
            if (NULL != val)
                CFNumberGetValue(val, kCFNumberLongType, &_width);
            val = CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
            if (NULL != val)
                CFNumberGetValue(val, kCFNumberNSIntegerType, &orientationValue);
            CFRelease(properties);
            
            // When we draw to Core Graphics, we lose orientation information,
            // which means the image below born of initWithCGIImage will be
            // oriented incorrectly sometimes. (Unlike the image born of initWithData
            // in didCompleteWithError.) So save it here and pass it on later.
            _orientation = orientationFromPropertyValue(orientationValue == -1 ? 1 : orientationValue);
        }
    }
}

- (UIImage *)imageForProgressive
{
    UIImage *progressiveImage = nil;
    const NSInteger receivedSize = _imageData.length;
    
    // Update the data source, we must pass ALL the data, not just the new bytes
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)_imageData, NULL);
    
    [self setImagePropertyValueWithImageSource:imageSource];
    
    if (_width + _height > 0 && receivedSize < _expectedContentLength) {
        // Create the image
        CGImageRef partialImageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
        
#ifdef TARGET_OS_IPHONE
        // Workaround for iOS anamorphic image
        if (partialImageRef) {
            const size_t partialHeight = CGImageGetHeight(partialImageRef);
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGContextRef bmContext = CGBitmapContextCreate(NULL, _width, _height, 8, _width * 4, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
            CGColorSpaceRelease(colorSpace);
            if (bmContext) {
                CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = _width, .size.height = partialHeight}, partialImageRef);
                CGImageRelease(partialImageRef);
                partialImageRef = CGBitmapContextCreateImage(bmContext);
                CGContextRelease(bmContext);
            }
            else {
                CGImageRelease(partialImageRef);
                partialImageRef = nil;
            }
        }
#endif
        
        if (partialImageRef) {
            progressiveImage = [UIImage imageWithCGImage:partialImageRef scale:1 orientation:_orientation];
            //                NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:self.request.URL];
            //                UIImage *scaledImage = [self scaledImageForKey:key image:image];
//            if (_isDecompressImage) {
//                image = GKHWebImageDecodedImageWithImage(image);
//            }
//            else {
//                //                    image = scaledImage;
//            }
            CGImageRelease(partialImageRef);
//
        }
    }
    
    CFRelease(imageSource);
    
    return progressiveImage;
}

- (GKHWebImageDowloaderProgressiveObject *)progressiveBlock
{
    unsigned long long receivedSize = _imageData.length;
    unsigned long long expectedContentLength = _expectedContentLength;
    UIImage *image = [self imageForProgressive];
    NSData *imageData = _imageData;
    NSURL *imageURL = _imageURL;
    GKHWebImageDowloaderProgressiveObject *progressiveImage = [[GKHWebImageDowloaderProgressiveObject alloc]
                initWithReceivedSize:receivedSize
               expectedContentLength:expectedContentLength
                               image:image
                           imageData:imageData
                            imageURL:imageURL];
    
    return progressiveImage;
}

- (UIImage *)imageForCompletedBlock
{
    UIImage *image = nil;
    //                    NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:self.request.URL];
    //                    image = [self scaledImageForKey:key image:image];
    
    // Do not force decoding animated GIFs
    if (!image.images) {
        if (_isDecompressImage) {
            image = GKHWebImageDecodedImageWithImage(image);
        }
    }

    return image;
}

- (GKHWebImageDowloaderCompletedObject *)completedBlock
{
    NSError *error = nil;
    UIImage *image = nil;
    GKHWebImageDownloaderState state = GKHWebImageDownloaderFailure;
    
    if (_imageData.length <= 0) {
        error = [GKHWebImageDowloaderErrorFactory errorWithCompletedErrorType:GKHWebImageDownloaderCompletedImageHasNoneData errorCode:GKHWebImageDownloaderDefaultCode];
    } else {
        image =  [self imageForCompletedBlock];
        if (CGSizeEqualToSize(image.size, CGSizeZero)) {
            error = [GKHWebImageDowloaderErrorFactory errorWithCompletedErrorType:GKHWebImageDownloaderCompletedImageHasNonePixel errorCode:GKHWebImageDownloaderDefaultCode];
            state = GKHWebImageDownloaderFailure;
            image = nil;
        } else {
            state = GKHWebImageDownloaderSuccess;
        }
    }
    
    GKHWebImageDowloaderCompletedObject *completedImage = [[GKHWebImageDowloaderCompletedObject alloc] initWithReceivedSize:_imageData.length expectedContentLength:_expectedContentLength image:image imageData:_imageData  imageURL:_imageURL state:state error:error];
    
    return completedImage;

}

+ (GKHWebImageDowloaderCompletedObject *)cancelBlockWithError:(NSError *)error imageURL:(NSURL *)imageURL
{
    GKHWebImageDowloaderCompletedObject *completedImage = [[GKHWebImageDowloaderCompletedObject alloc] initWithReceivedSize:0     expectedContentLength:0 image:nil imageData:nil imageURL:imageURL state:GKHWebImageDownloaderCancel error:error];
    
    return completedImage;
}

+ (GKHWebImageDowloaderCompletedObject *)failureBlockWithError:(NSError *)error imageURL:(NSURL *)imageURL
{
    GKHWebImageDowloaderCompletedObject *completedImage = [[GKHWebImageDowloaderCompletedObject alloc] initWithReceivedSize:0     expectedContentLength:0 image:nil imageData:nil imageURL:imageURL state:GKHWebImageDownloaderFailure error:error];
    
    return completedImage;
}

@end
