//
//  SearchViewController.m
//  Krossover Instagram
//
//  Created by Kevin Li on 7/22/14.
//  Copyright (c) 2014 Kevin Li. All rights reserved.
//

#import "SearchViewController.h"

@interface SearchViewController () {
    NSString *_selectedId;
}

@property (nonatomic, weak) IBOutlet UISearchBar *userSearch;
@property (nonatomic, weak) IBOutlet UITableView *resultsTable;

@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

@property (nonatomic, strong) NSMutableArray *resultsArray;

- (void)dismissKeyboard;

- (void)performSearch:(NSString *)searchTerm;

@end

@implementation SearchViewController

@synthesize userSearch, resultsTable, tapGesture;
@synthesize resultsArray;

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
    
    self.tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismissKeyboard)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissKeyboard {
    [self.userSearch resignFirstResponder];
    
    // remove the tap gesture recognizer
    [self.view removeGestureRecognizer:self.tapGesture];
}

#pragma mark - Search methods
- (void)performSearch:(NSString *)searchTerm {
    [InstagramDownloader searchForUser:searchTerm withCompletion:^(NSArray *searchResults, NSError *searchError) {
        if (searchResults == nil || searchError != nil) {
            // something went wrong
            NSString *errorDescription = searchError.localizedDescription;
            if (errorDescription == nil) {
                errorDescription = @"Something went wrong while performing the search.";
            }
            
            UIAlertView *searchError = [[UIAlertView alloc]initWithTitle:@"Search Error" message:errorDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [searchError show];
            return;
        }
        
        self.resultsArray = [searchResults mutableCopy];
        [self.resultsTable reloadData];
    }];
}

#pragma mark - Search bar delegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    // set up a tap gesture recognizer to dismiss keyboard on tap
    [self.view addGestureRecognizer:self.tapGesture];
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self dismissKeyboard];
    [self performSearch:searchBar.text];
}

#pragma mark - Table view delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.resultsArray) {
        return [self.resultsArray count];
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UserResultTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserResultCell"];
    
    cell.profileImage.image = [UIImage imageNamed:@"loading_profile.png"];
    
    // get the model
    UserProfile *profileItem = [self.resultsArray objectAtIndex:indexPath.row];
    cell.userNameLabel.text = profileItem.userName;
    cell.realNameLabel.text = profileItem.realName;
    
    if (profileItem.photo != nil) {
        // load the profile image if its cached
        cell.profileImage.image = profileItem.photo;
    }
    else {
        // otherwise load it on the fly
        [ImageDownloader lazyLoadImage:profileItem.photoUrl withCompletion:^(UIImage *downloadedImage, NSError *error) {
            if (downloadedImage != nil && error == nil) {
                profileItem.photo = downloadedImage;
                cell.profileImage.image = downloadedImage;
                
                // save the profile image back into the array
                [self.resultsArray replaceObjectAtIndex:indexPath.row withObject:profileItem];
            }
        }];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // a row was tapped

    // get the model
    UserProfile *profileItem = [self.resultsArray objectAtIndex:indexPath.row];
    
    _selectedId = profileItem.instagramId;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // start the segue
    [self performSegueWithIdentifier:@"SegueToProfile" sender:self];
}


#pragma mark - Prepare for segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"SegueToProfile"]) {
        
        ProfileViewController *destination = segue.destinationViewController;
        
        destination.sideloadProfile = YES;
        [destination loadUserProfile:_selectedId];
        
    }
}

@end
