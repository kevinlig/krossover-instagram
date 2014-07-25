//
//  SearchViewController.h
//  Krossover Instagram
//
//  Created by Kevin Li on 7/22/14.
//  Copyright (c) 2014 Kevin Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserResultTableViewCell.h"
#import "InstagramDownloader.h"
#import "ImageDownloader.h"
#import "ProfileViewController.h"

@interface SearchViewController : UIViewController <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@end
