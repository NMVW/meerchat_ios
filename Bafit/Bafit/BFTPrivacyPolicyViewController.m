//
//  BFTPrivacyPolicyViewController.m
//  Bafit
//
//  Created by Keeano Martin on 8/24/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTPrivacyPolicyViewController.h"
#import "BFTDataHandler.h"

@interface BFTPrivacyPolicyViewController ()

@end

@implementation BFTPrivacyPolicyViewController

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
    //set bakground color
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)acceptButton:(id)sender {
    [[BFTDataHandler sharedInstance] setPPAccepted:YES];
    [self performSegueWithIdentifier:@"confirmemail" sender:self];
}

- (IBAction)declineButton:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Privacy Policy" message:@"You must accept our privacy policy to be an active user of Meerchat" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
    [alert show];
}

- (IBAction)ipadbypassButton:(id)sender {
    [[BFTDataHandler sharedInstance] setPPAccepted:YES];
    [self performSegueWithIdentifier:@"confirmemail" sender:self];
}
@end
