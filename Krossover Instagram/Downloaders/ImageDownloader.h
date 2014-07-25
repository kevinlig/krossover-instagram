//
//  ImageDownloader.h
//  Krossover Instagram
//
//  Created by Kevin Li on 7/23/14.
//  Copyright (c) 2014 Kevin Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageDownloader : NSObject

typedef void(^imageDownloadCompletion)(UIImage *image, NSError *error);

+ (void)lazyLoadImage:(NSString *)webUrl withCompletion:(imageDownloadCompletion)completion;

@end
