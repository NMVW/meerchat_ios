//
//  BFTEmailConfirmationViewController.m
//  Bafit
//
//  Created by Joseph Pecoraro on 8/13/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTEmailConfirmationViewController.h"
#import "BFTDatabaseRequest.h"
#import "BFTDataHandler.h"

@interface BFTEmailConfirmationViewController () <UITextFieldDelegate>

@end

@implementation BFTEmailConfirmationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    //set background color
    //[self.view setBackgroundColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    [_emailSentTextLabel setText:[NSString stringWithFormat:@"Please enter the verification number sent to %@", [[BFTDataHandler sharedInstance] EDEmail]]];
    
    UIColor *orangeButtonBorder = [UIColor colorWithRed:240/255.0f green:162/255.0f blue:44/255.0f alpha:1];
    _submitVerificationButton.layer.cornerRadius = 5.0f;
    _submitVerificationButton.layer.borderWidth = 2.0f;
    _submitVerificationButton.layer.borderColor = [UIColor whiteColor].CGColor;
    _submitVerificationButton.clipsToBounds = YES;
    [_submitVerificationButton setBackgroundImage:[BFTEmailConfirmationViewController imageWithColor:[UIColor whiteColor] size:_submitVerificationButton.frame.size] forState:UIControlStateHighlighted];
    [_submitVerificationButton setTitleColor:orangeButtonBorder forState:UIControlStateHighlighted];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.verificationNumberTextField becomeFirstResponder];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)createUser:(id)sender {
    BFTDataHandler *data = [BFTDataHandler sharedInstance];
    NSString *UID = [[NSUUID UUID] UUIDString];
    [data setUID:UID];
    [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"createUser.php?UIDr=%@&BUN=%@&BAFemail=%@&RVC=%@&FBemail=%@&GPSlat=%.8f&GPSlon=%.8f", UID, [data BUN], [data EDEmail], self.verificationNumberTextField.text, [data FBEmail], [data Latitude], [data Longitude]] completionBlock:^(NSMutableData *data, NSError *error) {
        if (!error) {
            NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSString *tOrF = [response substringToIndex:1];
            BOOL boolResult = ([tOrF caseInsensitiveCompare:@"T"] == NSOrderedSame) ? YES : NO;
            NSArray *result = [response componentsSeparatedByString:@":"];
            
            //not sure what this returns if its successful
            if (boolResult) {
                NSLog(@"User Succesfully Created");
                [[BFTDataHandler sharedInstance] setEmailConfirmed:YES];
                [[BFTDataHandler sharedInstance] saveData];
                [self performSegueWithIdentifier:@"tomain" sender:self];
            }
            else {
                NSLog(@"User Not Created\n%@", response);
                [[[UIAlertView alloc] initWithTitle:@"Could Not Create User" message:result[1] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
            }
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"Could Not Create User" message:error.localizedDescription delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
        }
    }] startConnection];
}

//this is used to set the background color for the button when highlighted
+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size
{
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
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

@end
