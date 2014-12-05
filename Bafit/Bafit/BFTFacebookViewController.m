//
//  BFTViewController.m
//  Bafit
//
//  Created by Keeano Martin on 7/18/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTFacebookViewController.h"
#import "BFTDataHandler.h"
#import "BFTPostHandler.h"
#import "BFTDatabaseRequest.h"
#import "BFTAppDelegate.h"
#import "BFTConstants.h"

@interface BFTFacebookViewController ()

@end


@implementation BFTFacebookViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    //set background color
    [self.view setBackgroundColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    
    _data = [[BFTDataHandler alloc] init];
    
    //Facebook
    _loginButton.delegate = self;
    _loginButton.readPermissions = @[@"public_profile", @"email", @"user_friends"];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
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

}

-(void)loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)user {
    //this is getting called more than once for some reason, which was casuing multiple segues and issues with navigation
    static int fetchedInfoCounter = 0;
    if (fetchedInfoCounter > 0) {
        return;
    }
    fetchedInfoCounter++;
    
    NSString *email = [user objectForKey:@"email"];
    
    //To cover the people who have already registered
    if (![[BFTDataHandler sharedInstance] FBID]) {
        [self sendFBInformation:user];
        [[BFTDataHandler sharedInstance] setFBEmail:email];
        [[BFTDataHandler sharedInstance] setFBID:[user objectID]];
        [[BFTDataHandler sharedInstance] saveData];
    }

    [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"userExists.php?FBemail=%@", email] completionBlock:^(NSMutableData *data, NSError *error) {
        if (!error) {
            NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"Facebook Data: %@", response);
            NSArray *values = [response componentsSeparatedByString:@","];
            if (![values[0] isEqualToString:@""]) {
                //if the response is successful, we set the uid to the datahandler, and go to mainview, otherwise, we go to the loginview
                NSString *uid = values[0];
                [[BFTDataHandler sharedInstance] setUID:uid];
                NSString *BUN = values[1];
                [[BFTDataHandler sharedInstance] setBUN:BUN];
                [[BFTDataHandler sharedInstance] setFBEmail:email];
                [[BFTDataHandler sharedInstance] setInitialLogin:NO];
                [[BFTDataHandler sharedInstance] setPPAccepted:YES];
                [[BFTDataHandler sharedInstance] setEmailConfirmed:YES];
                [[BFTDataHandler sharedInstance] saveData];
                [self performSegueWithIdentifier:@"mainview" sender:self];
                
                //log the user into jabber
                [(BFTAppDelegate*)[[UIApplication sharedApplication] delegate] connectToJabber];
            }
            else {
                [self sendFBInformation:user];
                [[BFTDataHandler sharedInstance] setFBEmail:email];
                [[BFTDataHandler sharedInstance] setFBID:[user objectID]];
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

-(void)sendFBInformation:(id<FBGraphUser>)user {
    //I'm pretty sure we have all this, so don't bother sending to database
    NSLog(@"BF Info: %@", user);
    [[BFTDataHandler sharedInstance] setUserInfo:user];
    
    //pull friends list
    [FBRequestConnection startWithGraphPath:@"/me/friendlists" parameters:nil HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        NSLog(@"Friend Result: %@ \n\nSize: %.4f kb", result, [result length]/1024.0);
        
        NSLog(@"Sending FB Friends List");
        [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"sendFBdata.php?FBemail=%@Data=%@Flist=%@", [user objectForKey:@"email"], user, result] completionBlock:^(NSMutableData *data, NSError *error) {
            if (!error) {
                
            }
            else {
                
            }
        }] startConnection];
    }];
}

-(void)getProfilePicture {
    
}

-(BOOL)checkPP {
   // NSLog(@"%s", [[BFTDataHandler sharedInstance] PPAccepted]);
    //return *[[BFTDataHandler sharedInstance]PPAccepted];
    return false;
}

@end
