//
//  FeedTableViewController.m
//  Krossover Instagram
//
//  Created by Kevin Li on 7/22/14.
//  Copyright (c) 2014 Kevin Li. All rights reserved.
//

#import "FeedTableViewController.h"

@interface FeedTableViewController () {
    NSArray *_selectedComments;
    BOOL _offline;
    int _pageCount;
}

@property (nonatomic, strong) NSMutableArray *feedArray;
@property (nonatomic, strong) NSString *nextMax;

- (IBAction)refreshTable:(id)sender;
- (IBAction)playCellVideo:(id)sender;

- (void)loadNextPage;

- (MediaTableViewCell *)prepareMediaCellAt:(NSIndexPath *)indexPath;
- (UITableViewCell *)prepareLoadingCellAt:(NSIndexPath *)indexPath;

@end

@implementation FeedTableViewController

@synthesize feedArray, nextMax;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadUserFeed];
    
    // also listen for a login event, in which case we'll also reload the feed
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(loadUserFeed) name:@"loginEvent" object:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Handle user feed
- (void)loadUserFeed {
    // check if user has logged in
    if ([[NSUserDefaults standardUserDefaults]objectForKey:@"loggedIn"] == nil) {
        // don't bother, not logged in (we'll let the underlying tab bar controller handle this)
        return;
    }
    
    _pageCount = 1;
    
    // load the data
    [InstagramDownloader userFeedFromMaxId:nil usingCache:YES withCompletion:^(NSMutableArray *parsedArray, NSString *nextMaxId, NSError *error) {
        
        if (error != nil) {
            // something went wrong
            if (error.code != 400) {
                UIAlertView *errorAlert = [[UIAlertView alloc]initWithTitle:@"Feed Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [errorAlert show];
            }
            else {
                // the network is unavailable, read from cache
                self.feedArray = [InstagramDownloader offlineUserFeed];
                if (self.feedArray != nil) {
                    _offline = YES;
                    [self.tableView reloadData];
                }
            }
        }
        
        else if (parsedArray != nil) {
            
            _offline = NO;
            
            self.feedArray = parsedArray;
            
            if (nextMaxId != nil) {
                self.nextMax = nextMaxId;
            }
            
            // reload the table
            [self.tableView reloadData];
            
        }
        
       
        // stop the refresh control if pull to refresh was used
        [self.refreshControl endRefreshing];
    }];
    
    
}

- (void)loadNextPage {
    // this will probably break if there is no next max, so check and die if none exists
    if (self.nextMax == nil) {
        return;
    }
    
    _pageCount++;
    
    BOOL enableCaching = YES;
    if (_pageCount > 2) {
        // stop caching after the second page (40 items)
        enableCaching = NO;
    }
    
    // load the data
    [InstagramDownloader userFeedFromMaxId:self.nextMax usingCache:enableCaching withCompletion:^(NSMutableArray *parsedArray, NSString *nextMaxId, NSError *error) {
        
        if (error != nil) {
            // something went wrong
            
            UIAlertView *errorAlert = [[UIAlertView alloc]initWithTitle:@"Feed Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [errorAlert show];
        }
        
        else if (parsedArray != nil) {
            [self.feedArray addObjectsFromArray:parsedArray];
            
            if (nextMaxId != nil) {
                self.nextMax = nextMaxId;
            }
            else {
                self.nextMax = nil;
            }

            // append the new data
            [self.tableView reloadData];
            
        }
    }];
}

#pragma mark - Play video
- (IBAction)playCellVideo:(id)sender {
    UIButton *senderButton = sender;

    // get the media post model object
    MediaPost *currentPost = [self.feedArray objectAtIndex:senderButton.tag];
    
    // start the video playback
    MPMoviePlayerViewController *videoPlayer = [[MPMoviePlayerViewController alloc]init];
    [videoPlayer.moviePlayer setContentURL:[NSURL URLWithString:currentPost.videoUrl]];
    videoPlayer.moviePlayer.movieSourceType = MPMovieSourceTypeFile;
    [self presentMoviePlayerViewControllerAnimated:videoPlayer];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (self.nextMax != nil && self.feedArray != nil) {
        return [self.feedArray count] + 1;
    }
    else if (self.feedArray != nil) {
        return [self.feedArray count];
    }
    else {
        return 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (indexPath.row >= self.feedArray.count) {
        cell = [self prepareLoadingCellAt:indexPath];
    }
    else {
        cell = [self prepareMediaCellAt:indexPath];
    }
    
    return cell;
}

- (MediaTableViewCell *)prepareMediaCellAt:(NSIndexPath *)indexPath {
    MediaTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"MediaCell" forIndexPath:indexPath];
    
    // get the data model
    MediaPost *postItem = [self.feedArray objectAtIndex:indexPath.row];
    
    // populate the cell
    cell.userNameLabel.text = postItem.userName;
    cell.dateLabel.text = postItem.date;
    cell.captionLabel.text = postItem.caption;
    
    // generate a summary of likes and comments
    NSMutableString *socialString = [NSMutableString string];
    if (postItem.commentCount > 0) {
        [socialString appendFormat:@"%i comment",postItem.commentCount];
        if (postItem.commentCount > 1) {
            [socialString appendString:@"s"];
        }
        
        if (postItem.likeCount > 0) {
            [socialString appendString: @" / "];
        }
    }
    if (postItem.likeCount > 0) {
        [socialString appendFormat:@"%i like", postItem.likeCount];
        if (postItem.likeCount > 1) {
            [socialString appendString:@"s"];
        }
    }
    
    cell.socialSummary.text = socialString;

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if (postItem.commentCount == 0) {
        // remove cell accessory
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.videoButton.hidden = YES;
    if (postItem.mediaType == 2) {
        cell.videoButton.hidden = NO;
        
        // set up the video button
        cell.videoButton.tag = indexPath.row;
        [cell.videoButton addTarget:self action:@selector(playCellVideo:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    // check if the image is in the cache
    // it's probably not great that the cache is unbounded in size; it'll probably eventually crash the app
    if (postItem.imageData == nil) {
        // not in cache, lazy load it
        cell.imageView.image = [UIImage imageNamed:@"loading_photo.png"];
        
        [ImageDownloader lazyLoadImage:postItem.imageUrl withCompletion:^(UIImage *image, NSError *error) {
            if (error != nil || image == nil) {
                // something went wrong, let's just keep it on the loading image
            }
            else {
                cell.imageView.image = image;
                // add to cache
                postItem.imageData = image;
                [postItem saveImageToCoreData:image];
                
                // save the model back into the array
                [self.feedArray replaceObjectAtIndex:indexPath.row withObject:postItem];
            }
        }];
    }
    else {
        // in cache, display it
        cell.imageView.image = postItem.imageData;
    }
    return cell;
}

- (UITableViewCell *)prepareLoadingCellAt:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"LoadingCell" forIndexPath:indexPath];
    
    // if this has appeared then we should load the next page
    [self loadNextPage];
    
    return cell;
}



#pragma mark - Tap on cell to view comments
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // check if any comments exist for this post
    MediaPost *currentPost = [self.feedArray objectAtIndex:indexPath.row];
    
    if (currentPost.commentCount == 0) {
        return;
    }
    
    _selectedComments = currentPost.commentsArray;
    [self performSegueWithIdentifier:@"SegueToComments" sender:self];
}

#pragma mark - Pull to refresh
- (IBAction)refreshTable:(id)sender {
    [self loadUserFeed];
}

#pragma mark - Prepare for segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // prepare for comments segue
    if ([segue.identifier isEqualToString:@"SegueToComments"]) {
        // pass the selected comments over to the next view controller
        CommentsTableViewController *destination = segue.destinationViewController;
        destination.commentsArray = _selectedComments;
    }
}

@end
