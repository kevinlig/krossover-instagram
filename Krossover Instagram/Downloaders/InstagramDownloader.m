//
//  InstagramDownloader.m
//  Krossover Instagram
//
//  Created by Kevin Li on 7/22/14.
//  Copyright (c) 2014 Kevin Li. All rights reserved.
//

#import "InstagramDownloader.h"

@interface InstagramDownloader ()

+ (NSError *)authenticationError;

+ (NSMutableArray *)parseUserFeed:(NSArray *)dataArray usingCache:(BOOL)enableCache;
+ (NSArray *)parsePostComments:(NSArray *)dataArray;

+ (UserProfile *)parseProfile:(NSDictionary *)profileData;

@end


@implementation InstagramDownloader

+ (NSError *)authenticationError {
    NSDictionary *errorDictionary = @{NSLocalizedDescriptionKey: @"You are not logged in."};
    NSError *error = [NSError errorWithDomain:@"com.grumblus.krossover-interview" code:1 userInfo:errorDictionary];
    
    return error;
}

#pragma mark - Instagram feeds

+ (void)userFeedFromMaxId:(NSString *)maxId usingCache:(BOOL)enableCache withCompletion:(feedCompletion)completionBlock {
    
    // get the access token
    NSString *accessToken = [[LUKeychainAccess standardKeychainAccess]stringForKey:@"accessToken"];
    
    // die if the user isn't logged in
    if ([[NSUserDefaults standardUserDefaults]objectForKey:@"loggedIn"] == nil || accessToken == nil) {
        
        // return an authentication error
        completionBlock(nil, nil, [InstagramDownloader authenticationError]);
        
        return;
    }
    
    // grab the user feed
    NSString *feedStringUrl;
    if (maxId != nil) {
        // get subsequent pages
        feedStringUrl = [NSString stringWithFormat:@"https://api.instagram.com/v1/users/self/feed?access_token=%@&max_id=%@",accessToken, maxId];
    }
    else {
        // get initial page
        feedStringUrl = [NSString stringWithFormat:@"https://api.instagram.com/v1/users/self/feed?access_token=%@",accessToken];
    }
    
    NSURL *feedUrl = [NSURL URLWithString:feedStringUrl];

    
    // send the request asynchronously in the background
    [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:YES];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:feedUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    [request setHTTPMethod:@"GET"];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *feedError) {
        
        [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
        
        NSMutableArray *feedArray;
        NSString *nextMax;
        NSError *error;
        
        if (response != nil && data != nil && feedError == nil) {
            // we got a successful reponse
            
            // parse the JSON
            NSError *jsonError;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
            if (jsonError == nil) {
                
                // check if code 200 (success) was returned
                if ([[[responseDictionary objectForKey:@"meta"]objectForKey:@"code"]intValue] != 200) {
                    // bad response, likely OAuth related
                    NSDictionary *errorDictionary = @{NSLocalizedDescriptionKey: @"Instagram rejected the request."};
                    error = [NSError errorWithDomain:@"com.grumblus.krossover-interview" code:402 userInfo:errorDictionary];
                    completionBlock(feedArray, nextMax, error);
                    return;
                }
                
                // get the next max for pagination
                if ([responseDictionary objectForKey:@"pagination"]) {
                    nextMax = [[responseDictionary objectForKey:@"pagination"]objectForKey:@"next_max_id"];
                }
                
                // loop through the results and create the array
                if ([responseDictionary objectForKey:@"data"] != nil) {
                    feedArray = [InstagramDownloader parseUserFeed:[responseDictionary objectForKey:@"data"] usingCache:enableCache];
                }
            }
            else {
                NSDictionary *errorDictionary = @{NSLocalizedDescriptionKey: @"Could not parse Instagram feed."};
                error = [NSError errorWithDomain:@"com.grumblus.krossover-interview" code:401 userInfo:errorDictionary];
            }
        }
        else {
            // something went wrong
            NSDictionary *errorDictionary = @{NSLocalizedDescriptionKey: @"Could not retrieve Instagram feed."};
            error = [NSError errorWithDomain:@"com.grumblus.krossover-interview" code:400 userInfo:errorDictionary];
        }
        
        completionBlock(feedArray, nextMax, error);
    }];
}

+ (NSMutableArray *)parseUserFeed:(NSArray *)dataArray usingCache:(BOOL)enableCache {
    NSMutableArray *responseArray = [NSMutableArray array];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"MMM d"];
    
    for (NSDictionary *postItem in dataArray) {
        // check if item already exists in cache
        NSString *instagramId = [postItem objectForKey:@"id"];
        
        NSManagedObject *cachedObject = [MediaPost retrieveManagedObjectForPostId:instagramId];
        if (cachedObject != nil) {
            // it exists in the cache, just use the cached version
            MediaPost *cachedPost = [NSKeyedUnarchiver unarchiveObjectWithData:[cachedObject valueForKey:@"mediaPost"]];

            // the comments and likes may have changed, so update those
            cachedPost.likeCount = 0;
            if ([postItem objectForKey:@"likes"]) {
                cachedPost.likeCount = [[[postItem objectForKey:@"likes"]objectForKey:@"count"]intValue];
            }
            cachedPost.commentCount = 0;
            if ([postItem objectForKey:@"comments"] && [[[postItem objectForKey:@"comments"]objectForKey:@"count"]intValue] > 0) {
                cachedPost.commentCount = [[[postItem objectForKey:@"comments"]objectForKey:@"count"]intValue];
                
                // let's also parse the comments
                NSArray *commentsArray = [InstagramDownloader parsePostComments:[[postItem objectForKey:@"comments"]objectForKey:@"data"]];
                cachedPost.commentsArray = commentsArray;
            }
            
            // add the cached post to the feed array
            [responseArray addObject:cachedPost];
            
            // also save the updated model back into Core Data
            NSError *saveError;
            [cachedObject.managedObjectContext save:&saveError];
            
            continue;
        }
        
        
        // create a new MediaPost object for each item
        MediaPost *newPost = [[MediaPost alloc]init];
        
        newPost.userName = [[postItem objectForKey:@"user"]objectForKey:@"username"];
        newPost.instagramId = instagramId;
        
        // calculate and format the creation date
        NSDate *creationDate = [NSDate dateWithTimeIntervalSince1970:[[postItem objectForKey:@"created_time"]intValue]];
        newPost.date = [dateFormatter stringFromDate:creationDate];
        newPost.rawDate = creationDate;
        
        if ([[postItem objectForKey:@"type"]isEqualToString:@"image"]) {
            // image
            newPost.mediaType = 1;
        }
        else {
            // video
            newPost.mediaType = 2;
            newPost.videoUrl = [[[postItem objectForKey:@"videos"]objectForKey:@"low_resolution"]objectForKey:@"url"];
        }
        
        newPost.imageUrl = [[[postItem objectForKey:@"images"]objectForKey:@"low_resolution"]objectForKey:@"url"];
        
        newPost.caption = @"";
        if ([[postItem objectForKey:@"caption"]isKindOfClass:[NSDictionary class]]) {
            newPost.caption = [[postItem objectForKey:@"caption"]objectForKey:@"text"];
        }
        
        newPost.likeCount = 0;
        if ([postItem objectForKey:@"likes"]) {
            newPost.likeCount = [[[postItem objectForKey:@"likes"]objectForKey:@"count"]intValue];
        }
        
        newPost.commentCount = 0;
        if ([postItem objectForKey:@"comments"] && [[[postItem objectForKey:@"comments"]objectForKey:@"count"]intValue] > 0) {
            newPost.commentCount = [[[postItem objectForKey:@"comments"]objectForKey:@"count"]intValue];
            
            // let's also parse the comments
            NSArray *commentsArray = [InstagramDownloader parsePostComments:[[postItem objectForKey:@"comments"]objectForKey:@"data"]];
            newPost.commentsArray = commentsArray;
        }
        

        // save the post item to the cache
        if (enableCache) {
            [newPost saveToCoreData];
        }
        
        // add the post item to the array
        [responseArray addObject:newPost];
        
        newPost = nil;        
    }

    return responseArray;
}

+ (NSArray *)parsePostComments:(NSArray *)dataArray {
    // parse the comments
    NSMutableArray *commentsArray = [NSMutableArray array];
    
    for (NSDictionary *comment in dataArray) {
        // create a new comment object
        MediaComment *newComment = [[MediaComment alloc]init];
        
        newComment.userName = [[comment objectForKey:@"from"]objectForKey:@"username"];
        newComment.comment = [comment objectForKey:@"text"];
        
        [commentsArray addObject:newComment];
        
        newComment = nil;
    }
    
    return commentsArray;
    
}

#pragma mark - Offline cached user feed
+ (NSMutableArray *)offlineUserFeed {
    // get the Core Data context
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    NSManagedObjectContext *objectContext = appDelegate.managedObjectContext;
    
    // query Core Data for the 40 most recent posts
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"CachedPosts" inManagedObjectContext:objectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc]init];
    fetchRequest.entity = entityDescription;
    fetchRequest.fetchLimit = 40;
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]initWithKey:@"creation" ascending:NO];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    
    NSError *searchError;
    NSArray *resultArray = [objectContext executeFetchRequest:fetchRequest error:&searchError];
    if (resultArray != nil && [resultArray count] > 0) {
        
        // the result array contains managed objects, we need to grab the MediaPost object inside
        
        NSMutableArray *feedArray = [NSMutableArray array];
        for (NSManagedObject *resultItem in resultArray) {
            MediaPost *cachedPost = [NSKeyedUnarchiver unarchiveObjectWithData:[resultItem valueForKey:@"mediaPost"]];
            [feedArray addObject:cachedPost];
            
            cachedPost = nil;
        }
        
        return feedArray;
        
    }
    
    return nil;
}

#pragma mark - Recent Images From User
+ (void)recentItemsFrom:(NSString *)userId withCompletion:(recentFeedCompletion)completionBlock {
    // get the access token
    NSString *accessToken = [[LUKeychainAccess standardKeychainAccess]stringForKey:@"accessToken"];
    
    // die if the user isn't logged in
    if ([[NSUserDefaults standardUserDefaults]objectForKey:@"loggedIn"] == nil || accessToken == nil) {
        
        // return an authentication error
        completionBlock(nil, [InstagramDownloader authenticationError]);
        
        return;
    }
    
    NSURL *recentUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.instagram.com/v1/users/%@/media/recent?access_token=%@",userId, accessToken]];
    
    
    // send the request asynchronously in the background
    [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:YES];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:recentUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    [request setHTTPMethod:@"GET"];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *feedError) {
        
        [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
        
        NSMutableArray *recentArray;
        NSError *error;
        
        if (response != nil && data != nil && feedError == nil) {
            // we got a successful reponse
            
            // parse the JSON
            NSError *jsonError;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
            if (jsonError == nil) {
                
                // check if code 200 (success) was returned
                if ([[[responseDictionary objectForKey:@"meta"]objectForKey:@"code"]intValue] != 200) {
                    // bad response, likely OAuth related
                    NSDictionary *errorDictionary = @{NSLocalizedDescriptionKey: @"Instagram rejected the request."};
                    error = [NSError errorWithDomain:@"com.grumblus.krossover-interview" code:402 userInfo:errorDictionary];
                    completionBlock(recentArray, error);
                    return;
                }
                
                // loop through the results and create the array
                if ([responseDictionary objectForKey:@"data"] != nil && [[responseDictionary objectForKey:@"data"]count] > 0) {
                    
                    recentArray = [NSMutableArray array];
                    
                    for (NSDictionary *mediaItem in [responseDictionary objectForKey:@"data"]) {
                        // add image URLs to the array
                        NSString *imageUrl = [[[mediaItem objectForKey:@"images"]objectForKey:@"low_resolution"]objectForKey:@"url"];
                        [recentArray addObject:imageUrl];
                    }
                }
            }
            else {
                NSDictionary *errorDictionary = @{NSLocalizedDescriptionKey: @"Could not parse Instagram feed."};
                error = [NSError errorWithDomain:@"com.grumblus.krossover-interview" code:401 userInfo:errorDictionary];
            }
        }
        else {
            // something went wrong
            NSDictionary *errorDictionary = @{NSLocalizedDescriptionKey: @"Could not retrieve Instagram feed."};
            error = [NSError errorWithDomain:@"com.grumblus.krossover-interview" code:400 userInfo:errorDictionary];
        }
        
        completionBlock(recentArray, error);
    }];
}

#pragma mark - User Profiles
+ (void)userProfileAtId:(NSString *)userId withCompletion:(profileCompletion)completionBlock {
    
    // get the access token
    NSString *accessToken = [[LUKeychainAccess standardKeychainAccess]stringForKey:@"accessToken"];
    
    // die if the user isn't logged in
    if ([[NSUserDefaults standardUserDefaults]objectForKey:@"loggedIn"] == nil || accessToken == nil) {
        
        // return an authentication error
        completionBlock(nil, [InstagramDownloader authenticationError]);

        return;
    }
    
    if (userId == nil) {
        // if no user ID is provided, load the current user
        userId = @"self";
    }
    
    
    // make the Instagram API request
    NSURL *profileUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.instagram.com/v1/users/%@/?access_token=%@",userId,accessToken]];
    
    // send the request asynchronously in the background
    [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:YES];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:profileUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    [request setHTTPMethod:@"GET"];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *dataError) {
        
        [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
        
        UserProfile *returnProfile;
        NSError *returnError;
        
        if (response == nil || data == nil || dataError != nil) {
            // a network error occurred or server responded with nothing
            NSDictionary *errorDictionary = @{NSLocalizedDescriptionKey: @"Could not retrieve user profile."};
            returnError = [NSError errorWithDomain:@"com.grumblus.krossover-interview" code:500 userInfo:errorDictionary];
        }
        else {
            
            // parse the JSON
            NSError *jsonError;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
            if (jsonError == nil) {
                
                // check if code 200 (success) was returned
                if ([[[responseDictionary objectForKey:@"meta"]objectForKey:@"code"]intValue] != 200) {
                    // bad response, likely OAuth related
                    NSDictionary *errorDictionary = @{NSLocalizedDescriptionKey: @"Instagram rejected the request."};
                    returnError = [NSError errorWithDomain:@"com.grumblus.krossover-interview" code:402 userInfo:errorDictionary];
                }
                else {
                    // good response, parse it
                    returnProfile = [InstagramDownloader parseProfile:[responseDictionary objectForKey:@"data"]];
                }

            }
            else {
                // could not parse JSON
                NSDictionary *errorDictionary = @{NSLocalizedDescriptionKey: @"Could not parse user profile."};
                returnError = [NSError errorWithDomain:@"com.grumblus.krossover-interview" code:501 userInfo:errorDictionary];
            }
        }
        
        
        completionBlock(returnProfile, returnError);

    }];
    
    
}


+ (UserProfile *)parseProfile:(NSDictionary *)profileData {
    UserProfile *profile = [[UserProfile alloc]init];
    
    profile.instagramId = [profileData objectForKey:@"id"];
    profile.userName = [profileData objectForKey:@"username"];
    profile.realName = @"";
    if ([profileData objectForKey:@"full_name"] != nil) {
        profile.realName = [profileData objectForKey:@"full_name"];
    }
    profile.photoUrl = [profileData objectForKey:@"profile_picture"];
    
    if ([profileData objectForKey:@"counts"] != nil) {
        profile.media = [[[profileData objectForKey:@"counts"]objectForKey:@"media"]intValue];
        profile.followers = [[[profileData objectForKey:@"counts"]objectForKey:@"followed_by"]intValue];
        profile.following = [[[profileData objectForKey:@"counts"]objectForKey:@"follows"]intValue];
    }
    else {
        profile.media = 0;
        profile.followers = 0;
        profile.following = 0;
    }
    
    return profile;
}

#pragma mark - User search
+ (void)searchForUser:(NSString *)searchTerm withCompletion:(searchCompletion)completionBlock {
    // search for a user given the search string
    
    // get the access token
    NSString *accessToken = [[LUKeychainAccess standardKeychainAccess]stringForKey:@"accessToken"];
    
    // die if the user isn't logged in
    if ([[NSUserDefaults standardUserDefaults]objectForKey:@"loggedIn"] == nil || accessToken == nil) {
        
        // return an authentication error
        completionBlock(nil, [InstagramDownloader authenticationError]);
        
        return;
    }
    
    NSURL *searchUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.instagram.com/v1/users/search?q=%@&access_token=%@",[searchTerm stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]], accessToken]];
    
    
    // send the request asynchronously in the background
    [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:YES];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:searchUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    [request setHTTPMethod:@"GET"];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *feedError) {
        
        [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
        
        NSMutableArray *resultArray;
        NSError *returnError;
        
        if (response != nil && data != nil && feedError == nil) {
            // we got a successful reponse
            
            // parse the JSON
            NSError *jsonError;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
            if (jsonError == nil) {
                // check if code 200 (success) was returned
                if ([[[responseDictionary objectForKey:@"meta"]objectForKey:@"code"]intValue] != 200) {
                    // bad response, likely OAuth related
                    NSDictionary *errorDictionary = @{NSLocalizedDescriptionKey: @"Instagram rejected the request."};
                    returnError = [NSError errorWithDomain:@"com.grumblus.krossover-interview" code:402 userInfo:errorDictionary];
                }
                else {
                    // good response, parse it
                    NSArray *userArray = [responseDictionary objectForKey:@"data"];
                    
                    resultArray = [NSMutableArray array];
                    
                    for (NSDictionary *userItem in userArray) {
                        UserProfile *userProfile = [InstagramDownloader parseProfile:userItem];
                        [resultArray addObject:userProfile];
                    }
                }
                
            }
            else {
                // could not parse JSON
                NSDictionary *errorDictionary = @{NSLocalizedDescriptionKey: @"Could not parse search results."};
                returnError = [NSError errorWithDomain:@"com.grumblus.krossover-interview" code:601 userInfo:errorDictionary];
            }
        }
        else {
            // a network error occurred or server responded with nothing
            NSDictionary *errorDictionary = @{NSLocalizedDescriptionKey: @"Could not retrieve search results."};
            returnError = [NSError errorWithDomain:@"com.grumblus.krossover-interview" code:600 userInfo:errorDictionary];
        }
     
        completionBlock(resultArray, returnError);
    }];
}

@end
