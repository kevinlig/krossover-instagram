//
//  MediaPost.m
//  Krossover Instagram
//
//  Created by Kevin Li on 7/22/14.
//  Copyright (c) 2014 Kevin Li. All rights reserved.
//

#import "MediaPost.h"

@interface MediaPost ()

+ (NSManagedObjectContext *)retrieveCoreDataContext;

@end

@implementation MediaPost

@synthesize instagramId, userName, date, rawDate, mediaType, imageUrl, videoUrl, caption, commentCount, likeCount;

@synthesize commentsArray;

@synthesize imageData;

- (id)initWithCoder:(NSCoder *)aDecoder {
    // this, along with encodeWithCoder will allow the model to be written and read from NSData (so we can toss it into the SQLite database)
    
    self = [super init];
    
    if (self) {
        self.instagramId = [aDecoder decodeObjectForKey:@"instagramId"];
        self.userName = [aDecoder decodeObjectForKey:@"userName"];
        self.date = [aDecoder decodeObjectForKey:@"date"];
        self.rawDate = [aDecoder decodeObjectForKey:@"rawDate"];
        self.mediaType = [aDecoder decodeIntForKey:@"mediaType"];
        self.imageUrl = [aDecoder decodeObjectForKey:@"imageUrl"];
        self.videoUrl = [aDecoder decodeObjectForKey:@"videoUrl"];
        self.caption = [aDecoder decodeObjectForKey:@"caption"];
        self.commentCount = [aDecoder decodeIntForKey:@"commentCount"];
        self.likeCount = [aDecoder decodeIntForKey:@"likeCount"];
        self.commentsArray = [aDecoder decodeObjectForKey:@"commentsArray"];
        self.imageData = [aDecoder decodeObjectForKey:@"imageData"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.instagramId forKey:@"instagramId"];
    [aCoder encodeObject:self.userName forKey:@"userName"];
    [aCoder encodeObject:self.date forKey:@"date"];
    [aCoder encodeObject:self.rawDate forKey:@"rawDate"];
    [aCoder encodeInt:self.mediaType forKey:@"mediaType"];
    [aCoder encodeObject:self.imageUrl forKey:@"imageUrl"];
    [aCoder encodeObject:self.videoUrl forKey:@"videoUrl"];
    [aCoder encodeObject:self.caption forKey:@"caption"];
    [aCoder encodeInt:self.commentCount forKey:@"commentCount"];
    [aCoder encodeInt:self.likeCount forKey:@"likeCount"];
    [aCoder encodeObject:self.commentsArray forKey:@"commentsArray"];
    [aCoder encodeObject:self.imageData forKey:@"imageData"];
}


#pragma mark - Core Data methods
// this is is my first time using Core Data, so this is the result of a lot of Googling/Stackoverflow.
// additionally the cache is unbounded so queries will likely become slower and take up more space over time/as more pagination occurs

+ (NSManagedObjectContext *)retrieveCoreDataContext {
    // get the Core Data context
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    NSManagedObjectContext *objectContext = appDelegate.managedObjectContext;
    
    return objectContext;
}


- (BOOL)saveToCoreData {
    
    // check if post already exists in core data
    if ([MediaPost retrieveFromCoreData:self.instagramId] != nil) {
        // it already exists, die
        return NO;
    }
    
    NSManagedObjectContext *objectContext = [MediaPost retrieveCoreDataContext];
    
    // add a new record to Core Data
    NSManagedObject *postRecord = [NSEntityDescription insertNewObjectForEntityForName:@"CachedPosts" inManagedObjectContext:objectContext];
    [postRecord setValue:self.instagramId forKey:@"instagramId"];
    [postRecord setValue:self.rawDate forKey:@"creation"];
    [postRecord setValue:[NSKeyedArchiver archivedDataWithRootObject:self] forKey:@"mediaPost"];
    
    NSError *saveError;
    [objectContext save:&saveError];
    
    if (saveError != nil) {
        return NO;
    }
    
    return YES;
}

- (BOOL)saveImageToCoreData:(UIImage *)newImage {
    // get the post in question
    NSManagedObject *targetPost = [MediaPost retrieveManagedObjectForPostId:self.instagramId];
    if (targetPost == nil) {
        // no such post with that ID, die
        return NO;
    }
    
    MediaPost *postItem = [NSKeyedUnarchiver unarchiveObjectWithData:[targetPost valueForKey:@"mediaPost"]];
    
    // add the image data
    postItem.imageData = newImage;
    
    // get the Core Data context
    NSManagedObjectContext *objectContext = targetPost.managedObjectContext;
    
    // put the post model back into the managed object
    [targetPost setValue:[NSKeyedArchiver archivedDataWithRootObject:postItem] forKey:@"mediaPost"];

    // save the updated post entity
    NSError *saveError;
    [objectContext save:&saveError];
    if (saveError == nil) {
        return YES;
    }
    
    return NO;
}


+ (NSManagedObject *)retrieveManagedObjectForPostId:(NSString *)postId {
    // retrieve the managed object instance with the given post ID
    
    // get the Core Data context
    NSManagedObjectContext *objectContext = [MediaPost retrieveCoreDataContext];
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"CachedPosts" inManagedObjectContext:objectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc]init];
    fetchRequest.entity = entityDescription;
    // we only need the query to return one result
    fetchRequest.fetchLimit = 1;
    
    NSPredicate *dataSearch = [NSPredicate predicateWithFormat:@"(instagramId = %@)",postId];
    fetchRequest.predicate = dataSearch;
    
    NSError *searchError;
    NSArray *resultArray = [objectContext executeFetchRequest:fetchRequest error:&searchError];
    
    if ([resultArray count] > 0) {
        return [resultArray objectAtIndex:0];
    }
    
    return nil;

}

+ (MediaPost *)retrieveFromCoreData:(NSString *)postId {
    // retrieve an existing post from Core Data (or return nil if it does not exist)
    
    NSManagedObject *resultObject = [MediaPost retrieveManagedObjectForPostId:postId];
    
    if (resultObject != nil) {
        // post already exists
        MediaPost *foundPost = [NSKeyedUnarchiver unarchiveObjectWithData:[resultObject valueForKey:@"mediaPost"]];
        
        return foundPost;
    }
    
    return nil;
}

@end
