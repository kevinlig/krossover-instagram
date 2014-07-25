//
//  ProfileViewController.m
//  Krossover Instagram
//
//  Created by Kevin Li on 7/22/14.
//  Copyright (c) 2014 Kevin Li. All rights reserved.
//

#import "ProfileViewController.h"

@interface ProfileViewController () {
    int _loadStatus;
}

@property (nonatomic, weak) IBOutlet UILabel *userNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *realNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *postsLabel;
@property (nonatomic, weak) IBOutlet UILabel *followersLabel;
@property (nonatomic, weak) IBOutlet UILabel *followingLabel;

@property (nonatomic, weak) IBOutlet UIImageView *profileImage;

@property (nonatomic, weak) IBOutlet UICollectionView *recentPhotos;


@property (nonatomic, strong) NSMutableArray *recentPhotoArray;

@end

@implementation ProfileViewController

@synthesize userNameLabel, realNameLabel, postsLabel, followersLabel, followingLabel, profileImage;

@synthesize recentPhotos, recentPhotoArray;

@synthesize sideloadProfile;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.userNameLabel.text = @"Loading...";
    self.realNameLabel.text = @"";
    self.postsLabel.text = @"";
    self.followingLabel.text = @"";
    self.followersLabel.text = @"";
    
    if ([[NSUserDefaults standardUserDefaults]objectForKey:@"loggedIn"] != nil && self.sideloadProfile != YES) {
        // user is viewing their own profile
        
        // load the current user's profile
        [self loadUserProfile:nil];
        
        _loadStatus = 1;
        
        // add a log out button (only available on the current user's profile when accessed from the profile tab)
        UIBarButtonItem *logoutButton = [[UIBarButtonItem alloc]initWithTitle:@"Log Out" style:UIBarButtonItemStylePlain target:self action:@selector(logOut:)];
        [self.navigationItem setRightBarButtonItem:logoutButton];
        
        // we'll need this to handle the logout in order to jump back to the feed tab programmatically
        if (self.tabBarController.delegate == nil) {
            self.tabBarController.delegate = self;
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    // reload the view (for the current user's profile tab) if the initial load failed
    if ([[NSUserDefaults standardUserDefaults]objectForKey:@"loggedIn"] != nil && self.sideloadProfile != YES && _loadStatus == 3) {
        
        _loadStatus = 1;
        [self loadUserProfile:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Load profile
- (void)loadUserProfile: (NSString *)instagramId {
    [InstagramDownloader userProfileAtId:instagramId withCompletion:^(UserProfile *userProfile, NSError *profileError) {
        
        if (userProfile == nil || profileError != nil) {
            // something went wrong
            _loadStatus = 3;
            
            UIAlertView *errorAlert = [[UIAlertView alloc]initWithTitle:@"Profile Error" message:profileError.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [errorAlert show];
            
            return;
        }
        
        _loadStatus = 2;
        [self displayProfile: userProfile];

    }];
}

- (void)displayProfile:(UserProfile *)profile {
    self.userNameLabel.text = profile.userName;
    self.realNameLabel.text = profile.realName;

    NSMutableString *postsString = [NSMutableString stringWithFormat:@"%i post", profile.media];
    if (profile.media != 1) {
        [postsString appendString:@"s"];
    }
    self.postsLabel.text = postsString;

    self.followingLabel.text = [NSString stringWithFormat:@"%i following", profile.following];
    
    NSMutableString *followersString = [NSMutableString stringWithFormat:@"%i follower", profile.followers];
    if (profile.media != 1) {
        [followersString appendString:@"s"];
    }
    self.followersLabel.text = followersString;
    
    // load the profile image
    if (profile.photo == nil) {
        [ImageDownloader lazyLoadImage:profile.photoUrl withCompletion:^(UIImage *downloadedImage, NSError *error) {
            if (downloadedImage != nil && error == nil) {
                self.profileImage.image = downloadedImage;
            }
        }];
    }
    else {
        self.profileImage.image = profile.photo;
    }
    
    // load user's recent images
    [InstagramDownloader recentItemsFrom:profile.instagramId withCompletion:^(NSMutableArray *resultsArray, NSError *error) {
        if (resultsArray != nil && error == nil) {
            // load images
            self.recentPhotoArray = resultsArray;
            [self.recentPhotos reloadData];
        }
        
    }];
}

#pragma mark - Log out
- (IBAction)logOut:(id)sender {
    // this doesn't really work since the login page just logs the user back in
    
    // delete the access token
    [[LUKeychainAccess standardKeychainAccess]setString:@"" forKey:@"accessToken"];
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"loggedIn"];
    
    // go back to the feed view
    [self.tabBarController.delegate tabBarController:self.tabBarController shouldSelectViewController:[self.tabBarController.viewControllers objectAtIndex:0]];
    self.tabBarController.selectedIndex = 0;
    
    // notify the tab bar to check login status (which should fail and launch the login page)
    [[NSNotificationCenter defaultCenter]postNotificationName:@"CheckLogin" object:nil];
    
}

#pragma mark - Collection View delegate
- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    // quick hack, yeah there's a better way to support arbitrary screen sizes
    int maxImages = 9;
    if ([[UIScreen mainScreen]bounds].size.height < 500) {
        // 4 inch screen
        maxImages = 6;
    }
    
    if (self.recentPhotoArray == nil || [self.recentPhotoArray count] < maxImages) {
        if (self.recentPhotoArray != nil) {
            return [self.recentPhotoArray count];
        }
        
        return 0;
    }
    
    
    return maxImages;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    RecentImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ImageCell" forIndexPath:indexPath];
    
    // overwrite the cell with the loading image
    // (since all the cells are in view, the cells will never reload)
    cell.imageView.image = [UIImage imageNamed:@"loading_photo.png"];
    
    // load the image
    NSString *imageUrl = [self.recentPhotoArray objectAtIndex:indexPath.item];
    [ImageDownloader lazyLoadImage:imageUrl withCompletion:^(UIImage *downloadedImage, NSError *error) {
        if (downloadedImage != nil && error == nil) {
            cell.imageView.image = downloadedImage;
        }
    }];
    
    return cell;
}

#pragma mark - Tab bar delegate
// used to programmatically jump tabs
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    return YES;
}

@end
