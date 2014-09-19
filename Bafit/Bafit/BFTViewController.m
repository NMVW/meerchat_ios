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
#import "BFTDatabaseRequest.h"
#import "BFTAppDelegate.h"

@interface BFTViewController ()

@end


@implementation BFTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    //set background color
    [self.view setBackgroundColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    
    _data = [[BFTDataHandler alloc] init];
    
    //Facebook
    _loginButton.delegate = self;
    _loginButton.readPermissions = @[@"public_profile", @"email"];
    
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

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
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

#pragma mark FBLoginView Delegate

-(void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Logged in " message:@"You are logged in" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
    //[alert show];
    //[[BFTDataHandler sharedInstance] setPPAccepted:YES];
    
    //moved this check to the
    //check initial or Not and Facebook
    /*
    if([BFTLoginhandler initialLogin] == YES){
        [self performSegueWithIdentifier:@"initiallogin" sender:self];
    }else{
        [self performSegueWithIdentifier:@"mainview" sender:self];
    }*/
    
    //NSLog(@"%@", [[BFTDataHandler sharedInstance] PPAccepted]);
}

-(void)loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)user {
    //this is getting called more than once for some reason, which was casuing multiple segues and issues with navigation
    static int fetchedInfoCounter = 0;
    if (fetchedInfoCounter > 0) {
        return;
    }
    fetchedInfoCounter++;
    
    NSString *email = [user objectForKey:@"email"]; //@"poppyc@ufl.edu";
    [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"userExists.php?FBemail=%@", email] completionBlock:^(NSMutableData *data, NSError *error) {
        if (!error) {
            NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSArray *values = [response componentsSeparatedByString:@","];
            if (![values[0] isEqualToString:@""]) {
                //if the response is successful, we set the uid to the datahandler, and go to mainview, otherwise, we go to the loginview
                NSString *uid = values[0];
                [[BFTDataHandler sharedInstance] setUID:uid];
                NSString *BUN = values[1];
                [[BFTDataHandler sharedInstance] setBUN:BUN];
                [[BFTDataHandler sharedInstance] setFBEmail:email];
                [self performSegueWithIdentifier:@"mainview" sender:self];
                
                //log the user into jabber
                [(BFTAppDelegate*)[[UIApplication sharedApplication] delegate] connectToJabber];
            }
            else {
                [self sendFBDemographicInfo:user];
                [[BFTDataHandler sharedInstance] setFBEmail:email];
                [[BFTDataHandler sharedInstance] saveData];
                [self performSegueWithIdentifier:@"initiallogin" sender:self];
            }
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"Could Not Authenticate Facebook User" message:error.localizedDescription delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }] startConnection];
}

//Facebook recommends handling a bunch of different types of errors
-(void)loginView:(FBLoginView *)loginView handleError:(NSError *)error {
    NSString *alertMessage, *alertTitle;
    // If the user should perform an action outside of you app to recover,
    // the SDK will provide a message for the user, you just need to surface it.
    // This conveniently handles cases like Facebook password change or unverified Facebook accounts.
    if ([FBErrorUtility shouldNotifyUserForError:error]) {
        alertTitle = @"Facebook error";
        alertMessage = [FBErrorUtility userMessageForError:error];
        
        // This code will handle session closures that happen outside of the app
        // You can take a look at our error handling guide to know more about it
        // https://developers.facebook.com/docs/ios/errors
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession) {
        alertTitle = @"Session Error";
        alertMessage = @"Your current session is no longer valid. Please log in again.";
        
        // If the user has cancelled a login, we will do nothing.
        // You can also choose to show the user a message if cancelling login will result in
        // the user not being able to complete a task they had initiated in your app
        // (like accessing FB-stored information or posting to Facebook)
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
        NSLog(@"user cancelled login");
        
        // For simplicity, this sample handles other errors with a generic message
        // You can checkout our error handling guide for more detailed information
        // https://developers.facebook.com/docs/ios/errors
    } else {
        alertTitle  = @"Something went wrong";
        alertMessage = @"Please try again later.";
        NSLog(@"Unexpected error:%@", error);
    }
    
    if (alertMessage) {
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMessage
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

-(void)sendFBDemographicInfo:(id<FBGraphUser>)user {
    NSLog(@"Sending FB Demographics");
}


-(BOOL)checkPP {
   // NSLog(@"%s", [[BFTDataHandler sharedInstance] PPAccepted]);
    //return *[[BFTDataHandler sharedInstance]PPAccepted];
    return false;
}

@end
