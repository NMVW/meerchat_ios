//
//  BFTInitialLoginViewController.m
//  Bafit
//
//  Created by Keeano Martin on 7/27/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTSignupViewController.h"
#import "BFTDataHandler.h"
#import "BFTDatabaseRequest.h"
#import "BFTConstants.h"

@interface BFTSignupViewController ()

@end

@implementation BFTSignupViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    //set background color
    [self.view setBackgroundColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    self.view.userInteractionEnabled = YES;
    
    UITapGestureRecognizer* tapper = [[UITapGestureRecognizer alloc]
              initWithTarget:self action:@selector(handleSingleTap:)];
    tapper.cancelsTouchesInView = NO;
    [self.bgControl addGestureRecognizer:tapper];
    
    _initialUsername.autocorrectionType = UITextAutocorrectionTypeNo;
    _schoolEmail.autocorrectionType = UITextAutocorrectionTypeNo;
    
    _initialUsername.delegate = self;
    _schoolEmail.delegate = self;
    
    //Initialize username error label
    _usernameErrorLabel = [[UILabel alloc] initWithFrame:CGRectOffset(self.initialUsername.frame, 0, 30)];
    _usernameErrorLabel.textAlignment = NSTextAlignmentCenter;
    _usernameErrorLabel.textColor = [UIColor colorWithRed:255/255.0f green:50/255.0f blue:0 alpha:1];
    _usernameErrorLabel.font = [UIFont boldSystemFontOfSize:14];
    
    _initialUsername.layer.borderColor=[[UIColor redColor]CGColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    self.nextBtn.userInteractionEnabled = YES;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    [super viewWillDisappear:animated];
}

//hide keyboard when view is touched
- (void)handleSingleTap:(UITapGestureRecognizer *) sender
{
    [self.view endEditing:YES];
}

- (IBAction)checkUser:(id)sender {
    
    self.nextBtn.userInteractionEnabled = NO;
    
    if ([self validateEmail:[_schoolEmail text]]) {
        //Passed School email
        BFTDataHandler *handler = [BFTDataHandler sharedInstance];
        [handler setEDEmail:self.schoolEmail.text];
        if (self.usernameNeedsUpdating) {
            //sychronously update the username is valid.. this has to be done before we can continue, otherwise the username may not be unique
            [self verifyUniqueUsername:YES];
        }
        if (self.usernameIsUnique) {
            
            self.nextBtn.userInteractionEnabled = NO;
            
            [handler setBUN:self.initialUsername.text];
            [handler saveData];
            
            //email and username are good, so we need to send them a verification email
            [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"verifyEmail.php?BAFemail=%@", self.schoolEmail.text] trueOrFalseBlock:^(BOOL successful, NSError *error) {
                if (!error) {
                    if (!successful) {
                        [[[UIAlertView alloc] initWithTitle:@"Unable To Send Verification Email" message:nil delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
                    }
                    else {
                        //passed username and email, focus on navigation
                        
                        //go to email confirmation page
                        [self performSegueWithIdentifier:@"emailConfirm" sender:self];
                    }
                }
                else {
                    [[[UIAlertView alloc] initWithTitle:@"Unable To Send Verification Email" message:error.localizedDescription delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
                }
            }] startConnection];
        } else{
            
            self.nextBtn.userInteractionEnabled = YES;
            
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
        
        self.nextBtn.userInteractionEnabled = YES;
        
        [[[UIAlertView alloc] initWithTitle:@"Could not Register" message:@"Please enter a valid email address" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
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
            }
            else {
                [_usernameErrorLabel setText:@""];
                self.initialUsername.layer.borderWidth = 0.0f;
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

// String compare user email to regex for ANY valid email address
-(BOOL)validateEmail:(NSString*)email {
    if ([email isEqualToString:@""]) {
        return NO;
    }
    NSString *regex = @"[^@]+@[A-Za-z0-9.-]+\\.[A-Za-z]+";
    NSPredicate *emailPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [emailPredicate evaluateWithObject:email];
}

- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark TextField

- (IBAction)backgroundTapped:(id)sender {
    [self.view endEditing:YES];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField.tag == 1)
    {
        [self.initialUsername becomeFirstResponder];
        return NO;
    }
    else
    {
        return YES;
    }
    
    return YES;
}

//this is called when the email text field returns
- (IBAction)editr:(id)sender {
    [sender resignFirstResponder];
}

//this is called when the username text field returns
- (IBAction)editreturn:(id)sender {
    [sender resignFirstResponder];

    [self verifyUniqueUsername:NO];
}

- (IBAction)usernameTextChanged:(id)sender {
    self.usernameNeedsUpdating = YES;
}

//show/hide the keyboard
- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    CGSize kbSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect f = self.view.frame;
        f.origin.y -= kbSize.height;
        self.view.frame = f;
    }];
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    CGSize kbSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect f = self.view.frame;
        f.origin.y += kbSize.height;
        self.view.frame = f;
    }];
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
