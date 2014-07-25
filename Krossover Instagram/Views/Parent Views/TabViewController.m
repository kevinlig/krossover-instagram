//
//  TabViewController.m
//  Krossover Instagram
//
//  Created by Kevin Li on 7/22/14.
//  Copyright (c) 2014 Kevin Li. All rights reserved.
//

#import "TabViewController.h"

@interface TabViewController ()

- (void)checkUserStatus;

@end

@implementation TabViewController

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
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(checkUserStatus) name:@"CheckLogin" object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [self checkUserStatus];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)checkUserStatus {
    if ([[NSUserDefaults standardUserDefaults]objectForKey:@"loggedIn"] == nil) {
        [self performSegueWithIdentifier:@"SegueToLogin" sender:nil];
    }
}

@end
