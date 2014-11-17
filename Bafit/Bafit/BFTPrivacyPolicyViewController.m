//
//  BFTPrivacyPolicyViewController.m
//  Bafit
//
//  Created by Keeano Martin on 8/24/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTPrivacyPolicyViewController.h"
#import "BFTDataHandler.h"
#import "BFTConstants.h"

@interface BFTPrivacyPolicyViewController ()

@end

@implementation BFTPrivacyPolicyViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    //set bakground color
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self.view setBackgroundColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    NSString *fullURL = @"http://bafit.mobi/PrivacyPolicy_Terms";
    NSURL *url = [NSURL URLWithString:fullURL];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    if(requestObj != nil){
        [_privacyWebView loadRequest:requestObj];
    }else{
        NSLog(@"Error in oading PDF for Preview");
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)acceptButton:(id)sender {
    [[BFTDataHandler sharedInstance] setPPAccepted:YES];
    [self performSegueWithIdentifier:@"confirmemail" sender:self];
}

- (IBAction)declineButton:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Privacy Policy" message:@"You must accept our privacy policy to be an active user of Meerchat" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
    [alert show];
}

@end
