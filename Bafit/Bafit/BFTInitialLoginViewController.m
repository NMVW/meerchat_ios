//
//  BFTInitialLoginViewController.m
//  Bafit
//
//  Created by Keeano Martin on 7/27/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTInitialLoginViewController.h"
#import "BFTDataHandler.h"
#import "BFTDatabaseRequest.h"

@interface BFTInitialLoginViewController ()

@end

@implementation BFTInitialLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    //set background color
    [self.view setBackgroundColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    _initialUsername.delegate = self;
    _schoolEmail.delegate = self;
    
    //Tap gesture recognizer to end editing of the textfields when the background is tapped
    UITapGestureRecognizer *keyboardDismissTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [_scrollView addGestureRecognizer:keyboardDismissTap];
    
    //Initialize username error label
    _usernameErrorLabel = [[UILabel alloc] initWithFrame:CGRectOffset(self.initialUsername.frame, 0, 32)];
    _usernameErrorLabel.textAlignment = NSTextAlignmentCenter;
    _usernameErrorLabel.textColor = [UIColor colorWithRed:255/255.0f green:50/255.0f blue:0 alpha:1];
    _usernameErrorLabel.font = [UIFont boldSystemFontOfSize:14];
    [self.scrollView addSubview:_usernameErrorLabel];
    
    _initialUsername.layer.borderColor=[[UIColor redColor]CGColor];
    _initialUsername.layer.cornerRadius = 7.0f;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (IBAction)checkUser:(id)sender {
    if ([[_schoolEmail text] length] >= 1) {
        //Passed School email
        BFTDataHandler *handler = [BFTDataHandler sharedInstance];
        [handler setEDEmail:[NSString stringWithFormat:@"%@@ufl.edu", self.schoolEmail.text]];
        if (self.usernameNeedsUpdating) {
            //sychronously update the username is valid.. this has to be done before we can continue, otherwise the username may not be unique
            [self verifyUniqueUsername:YES];
        }
        if (self.usernameIsUnique) {
            //passed username and email, focus on navigation
            [handler setInitialLogin:false];
            [handler setBUN:self.initialUsername.text];
            //email and username are good, so we need to send them a verification email
            [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"verifyEmail.php?BAFemail=%@@ufl.edu", self.schoolEmail.text] trueOrFalseBlock:^(BOOL successful, NSError *error) {}] startConnection];
            
            //go to email confirmation page
            [self performSegueWithIdentifier:@"emailConfirm" sender:self];
        } else{
            if (self.couldNotConnect) {
                NSLog(@"Connection Error");
                [[[UIAlertView alloc] initWithTitle:@"Could not Register" message:@"Unable to Connect to Database" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
            }
            else {
                NSLog(@"Username is not unique");
                [[[UIAlertView alloc] initWithTitle:@"Could not Register" message:@"Username Is Not Unique" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
            }
        }
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Could not Register" message:@"Please enter an email address" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
        NSLog(@"Email is incorrect");
    }
}

-(void)verifyUniqueUsername:(BOOL)isSynchronous {
    BFTDatabaseRequest *request = [[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"uniqueUN.php?BUN=%@", self.initialUsername.text] trueOrFalseBlock:^(BOOL isUnique, NSError *error) {
        if (!error) {
            self.couldNotConnect = NO;
            self.usernameIsUnique = isUnique;
            self.usernameNeedsUpdating = NO;
            if (!isUnique) {
                self.initialUsername.layer.borderWidth= 2.0f;
                [_usernameErrorLabel setText:@"Username Must Be Unique"];
                [_checkMark setBackgroundImage:[UIImage imageNamed:@"checkmarkusernameblue.png"] forState:UIControlStateNormal];
            }
            else {
                [_usernameErrorLabel setText:@""];
                self.initialUsername.layer.borderWidth = 0.0f;
                [_checkMark setBackgroundImage:[UIImage imageNamed:@"checkmarkusername.png"] forState:UIControlStateNormal];
            }
        }
        else {
            self.couldNotConnect = YES;
        }
    }];
    if (isSynchronous) {
        [request startSynchronousConnection];
    }
    else {
        [request startConnection];
    }
}

#pragma mark TextField

-(void)dismissKeyboard {
    [_scrollView endEditing:YES];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return NO;
}

//this is called when the email text field returns
- (IBAction)editr:(id)sender {
    [sender resignFirstResponder];
}

//this is called when the username text field returns
- (IBAction)editreturn:(id)sender {
    [sender resignFirstResponder];
    [self.scrollView setContentOffset:CGPointZero animated:YES];
    [self verifyUniqueUsername:NO];
}

//adjust view for keyabord to edit the username textfield
- (IBAction)didBeginEdit:(id)sender {
    
    CGSize keyboardSize = CGSizeMake(320, 216);
    
    CGPoint buttonOrigin = _checkMark.frame.origin;
    
    CGFloat buttonHeight = _checkMark.frame.size.height;
    
    CGRect visibleRect = self.view.frame;
    
    visibleRect.size.height -= keyboardSize.height;
    
    if (!CGRectContainsPoint(visibleRect, buttonOrigin)){
        
        CGPoint scrollPoint = CGPointMake(0.0, buttonOrigin.y - visibleRect.size.height + buttonHeight);
        
        [self.scrollView setContentOffset:scrollPoint animated:YES];
        
    }
}

- (IBAction)usernameTextChanged:(id)sender {
    self.usernameNeedsUpdating = YES;
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
