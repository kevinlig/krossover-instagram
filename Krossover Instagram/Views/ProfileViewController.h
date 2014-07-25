//
//  ProfileViewController.h
//  Krossover Instagram
//
//  Created by Kevin Li on 7/22/14.
//  Copyright (c) 2014 Kevin Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LUKeychainAccess.h"
#import "InstagramDownloader.h"
#import "ImageDownloader.h"
#import "RecentImageCell.h"

@interface ProfileViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UITabBarControllerDelegate>

@property BOOL sideloadProfile;

- (void)displayProfile:(UserProfile *)profile;
- (void)loadUserProfile: (NSString *)instagramId;

- (IBAction)logOut:(id)sender;

@end
