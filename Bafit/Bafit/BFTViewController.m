//
//  BFTViewController.m
//  Bafit
//
//  Created by Keeano Martin on 7/18/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTViewController.h"
#import "BFTDataHandler.h"
#import "BFTLoginhandler.h"

@interface BFTViewController ()

@end


@implementation BFTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _data = [[BFTDataHandler alloc]init];
    
    //Facebook
    _loginButton.delegate = self;
    
    _thumbURLS = [[NSMutableArray alloc] initWithObjects:@"http://bafit.mobi/userPosts/thumb/v1.jpeg",
                  @"http://bafit.mobi/userPosts/thumb/v2.jpeg",
                  @"http://bafit.mobi/userPosts/thumb/v3.jpeg",
                  @"http://bafit.mobi/userPosts/thumb/v4.jpeg",
                  @"http://bafit.mobi/userPosts/thumb/v5.jpeg",
                  @"http://bafit.mobi/userPosts/thumb/v6.jpeg",
                  @"http://bafit.mobi/userPosts/thumb/v7.jpeg",
                  @"http://bafit.mobi/userPosts/thumb/v8.jpeg",
                  @"http://bafit.mobi/userPosts/thumb/v9.jpeg",
                  @"http://bafit.mobi/userPosts/thumb/v10.jpeg", nil];
    
//    [self saveImagesToArray];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)PolicyAlert:(id)sender {
    
    UIAlertView *policyAlert = [[UIAlertView alloc] initWithTitle:@"Privacy Policy" message:@"We never post anything to your Facebook \n\nWe never display any of your personal information besides the screen name you choose \n\nWe use Facebook to see friends, age, and interests" delegate:self cancelButtonTitle:@"Disagree" otherButtonTitles:@"Agree", nil];
    [policyAlert show];
}

//-(void)saveImagesToArray {
//       for (int i = 0; i < [_thumbURLS count]; i++) {
//            NSURL *imageURL = [NSURL URLWithString:[_thumbURLS objectAtIndex:i]];
//          dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//                NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
//               dispatch_async(dispatch_get_main_queue(), ^{
//                   UIImage *newImageObject = [[UIImage alloc] initWithData:imageData];
//                   NSMutableArray *images = [[NSMutableArray alloc] init];
//                   images = [[BFTDataHandler sharedInstance] images];
//                   [images addObject:newImageObject];
//                });
//            });
//        }
//}


-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    
    
    switch (buttonIndex) {
        case 0:
            //clicked disagree
            //[[BFTDataHandler sharedInstance] setPPAccepted:false];
            break;
        case 1:
            //clicked agree
            //[BFTDataHandler sharedInstance].PPAccepted = true;
            break;
            
        default:
            break;
    }
}

-(void)loginViewShowingLoggedInUser:(FBLoginView *)loginView
{
    //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Logged in " message:@"You are logged in" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
    //[alert show];
    //[[BFTDataHandler sharedInstance] setPPAccepted:YES];
    
    //check initial or Not and Facebook
    if([BFTLoginhandler initialLogin] == 1){
        [self performSegueWithIdentifier:@"initiallogin" sender:self];
    }else{
        
    [self performSegueWithIdentifier:@"mainview" sender:self];
    }
    
    //NSLog(@"%@", [[BFTDataHandler sharedInstance] PPAccepted]);
    
}

-(BOOL)checkPP {
   // NSLog(@"%s", [[BFTDataHandler sharedInstance] PPAccepted]);
    //return *[[BFTDataHandler sharedInstance]PPAccepted];
    return false;
}
@end
