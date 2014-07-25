//
//  CommentsTableViewController.h
//  Krossover Instagram
//
//  Created by Kevin Li on 7/23/14.
//  Copyright (c) 2014 Kevin Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MediaComment.h"
#import "CommentTableViewCell.h"

@interface CommentsTableViewController : UITableViewController

@property (nonatomic, strong) NSArray *commentsArray;

@end
