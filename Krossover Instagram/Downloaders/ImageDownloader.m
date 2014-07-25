//
//  ImageDownloader.m
//  Krossover Instagram
//
//  Created by Kevin Li on 7/23/14.
//  Copyright (c) 2014 Kevin Li. All rights reserved.
//

#import "ImageDownloader.h"

@implementation ImageDownloader

+ (void)lazyLoadImage:(NSString *)webUrl withCompletion:(imageDownloadCompletion)completion {
    
    // download the image
    NSURL *imageUrl = [NSURL URLWithString:webUrl];
    
    // send the request asynchronously in the background
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:imageUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    [request setHTTPMethod:@"GET"];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *imageError) {
        
        UIImage *downloadedImage;
        NSError *downloadError;

        
        if (response != nil && data != nil && imageError == nil) {
            // all went well
            downloadedImage = [UIImage imageWithData:data];
        }
        else {
            // something went wrong
            NSDictionary *errorDictionary = @{NSLocalizedDescriptionKey: @"The image could not be downloaded."};
            downloadError = [NSError errorWithDomain:@"com.grumblus.krossover-interview" code:300 userInfo:errorDictionary];
        }
        
        
        completion(downloadedImage, downloadError);
    }];
}

@end
