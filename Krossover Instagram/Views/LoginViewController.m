//
//  LoginViewController.m
//  Krossover Instagram
//
//  Created by Kevin Li on 7/22/14.
//  Copyright (c) 2014 Kevin Li. All rights reserved.
//

#import "LoginViewController.h"

@interface LoginViewController ()

@property (nonatomic, weak) IBOutlet UIWebView *loginWebView;

- (void) displayLoginPage;
- (void) dismissLogin;

@end

@implementation LoginViewController

@synthesize loginWebView;

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [self displayLoginPage];
}

- (void) displayLoginPage {
    // load the login page
    NSURL *loginUrl = [NSURL URLWithString:@"https://instagram.com/oauth/authorize/?client_id=1517db1a40454754a8472979d1ce6ef0&redirect_uri=krossoverprotocol://landing&response_type=token"];
    NSURLRequest *loginRequest = [NSURLRequest requestWithURL:loginUrl];
    [self.loginWebView loadRequest:loginRequest];
}

- (void) dismissLogin {
    [self.parentViewController dismissViewControllerAnimated:YES completion:^(void) {
        // send a login event to the rest of the app
        [[NSNotificationCenter defaultCenter]postNotificationName:@"loginEvent" object:nil];
    }];
}

#pragma mark - Web View Delegate
- (void)webViewDidStartLoad:(UIWebView *)webView {
    // show the status bar spinner
    [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    // stop the status bar spinner
    [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    // stop the status bar spinner
    [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    // catch requests to the krossoverprotocol protocol
    if ([request.URL.scheme isEqualToString:@"krossoverprotocol"]) {
        // grab the access token
        
        // get the string version of the URL that the web view is trying to use
        NSString *urlString = request.URL.relativeString;
        
        // check if the user denied access
        if ([urlString rangeOfString:@"error"].location != NSNotFound) {
            // user denied access
            UIAlertView *deniedError = [[UIAlertView alloc]initWithTitle:@"Access Denied" message:@"The app was not granted access to your Instagram account." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [deniedError show];
            deniedError = nil;
        }
        else if ([urlString rangeOfString:@"#access_token="].location != NSNotFound) {
            // we got the access token
            NSString *accessToken = [urlString substringFromIndex:41];

            // save the access token
            [[LUKeychainAccess standardKeychainAccess]setString:accessToken forKey:@"accessToken"];
            [[NSUserDefaults standardUserDefaults]setObject:@(1) forKey:@"loggedIn"];
            
            // dismiss the modal (on a delay in case this is the first load, which causes a clash with the initial modal animation)
            [self performSelector:@selector(dismissLogin) withObject:nil afterDelay:0.5f];
            
        }
        
        return NO;
    }

    return YES;
}


@end
