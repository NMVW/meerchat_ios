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
    if ([[_schoolEmail text] length] >= 3) {
        //Passed School email
        BFTDataHandler *handler = [BFTDataHandler sharedInstance];
        [handler setEDEmail:[NSString stringWithFormat:@"%@@ufl.edu", self.schoolEmail.text]];
        if (self.usernameIsUnique) {
            //passed username and email, focus on navigation
            [handler setInitialLogin:false];
            [handler setBUN:self.initialUsername.text];
            //email and username are good, so we need to send them a verification email
            [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"verifyEmail.php?BAFemail=%@@ufl.edu", self.schoolEmail.text] trueOrFalseBlock:^(BOOL successful) {}] startConnection];
            
            //go to email confirmation page
            [self performSegueWithIdentifier:@"emailConfirm" sender:self];
        } else{
            //username incorrect
            NSLog(@"Username is not unique");
        }
    } else {
        //email incorrect
        NSLog(@"Email is incorrect");
    }
}

-(void)verifyUniqueUsername {
    [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"uniqueUN.php?BUN=%@", self.initialUsername.text] trueOrFalseBlock:^(BOOL isUnique) {
        self.usernameIsUnique = isUnique;
        if (!isUnique) {
            self.initialUsername.layer.borderWidth= 2.0f;
            [_usernameErrorLabel setText:@"Username Must Be Unique"];
        }
        else {
            [_usernameErrorLabel setText:@""];
            self.initialUsername.layer.borderWidth = 0.0f;
        }
    }] startConnection];
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
    [self verifyUniqueUsername];
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
