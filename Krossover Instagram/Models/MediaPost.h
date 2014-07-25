//
//  MediaPost.h
//  Krossover Instagram
//
//  Created by Kevin Li on 7/22/14.
//  Copyright (c) 2014 Kevin Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MediaComment.h"
#import "AppDelegate.h"

@interface MediaPost : NSObject <NSCoding>

@property (nonatomic, strong) NSString *instagramId;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *date;
@property (nonatomic, strong) NSDate *rawDate;
@property int mediaType;
@property (nonatomic, strong) NSString *imageUrl;
@property (nonatomic, strong) NSString *videoUrl;
@property (nonatomic, strong) NSString *caption;
@property int commentCount;
@property int likeCount;

@property (nonatomic, strong) NSArray *commentsArray;

@property (nonatomic, strong) UIImage *imageData;

- (BOOL)saveToCoreData;
- (BOOL)saveImageToCoreData:(UIImage *)newImage;

+ (NSManagedObject *)retrieveManagedObjectForPostId:(NSString *)postId;
+ (MediaPost *)retrieveFromCoreData:(NSString *)postId;

@end
