//
//  InstagramDownloader.h
//  Krossover Instagram
//
//  Created by Kevin Li on 7/22/14.
//  Copyright (c) 2014 Kevin Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LUKeychainAccess.h"
#import "AppDelegate.h"
#import "MediaPost.h"
#import "UserProfile.h"

@interface InstagramDownloader : NSObject

typedef void(^feedCompletion)(NSMutableArray *feedArray, NSString *nextMax, NSError *error);
typedef void(^recentFeedCompletion)(NSMutableArray *recentArray, NSError *error);
typedef void(^profileCompletion)(UserProfile *profile, NSError *error);
typedef void(^searchCompletion)(NSArray *resultArray, NSError *error);

+ (void)userFeedFromMaxId:(NSString *)maxId usingCache:(BOOL)enableCache withCompletion:(feedCompletion)completionBlock;
+ (NSMutableArray *)offlineUserFeed;

+ (void)recentItemsFrom:(NSString *)userId withCompletion:(recentFeedCompletion)completionBlock;

+ (void)userProfileAtId:(NSString *)userId withCompletion:(profileCompletion)completionBlock;

+ (void)searchForUser:(NSString *)searchTerm withCompletion:(searchCompletion)completionBlock;

@end
