//
//  FeedTableViewController.h
//  Krossover Instagram
//
//  Created by Kevin Li on 7/22/14.
//  Copyright (c) 2014 Kevin Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "InstagramDownloader.h"
#import "ImageDownloader.h"
#import "MediaTableViewCell.h"
#import "CommentsTableViewController.h"

@interface FeedTableViewController : UITableViewController


- (void)loadUserFeed;

@end
