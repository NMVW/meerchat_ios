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
    
    //Initialize username error label
    _usernameErrorLabel = [[UILabel alloc] initWithFrame:CGRectOffset(self.initialUsername.frame, 0, 32)];
    _usernameErrorLabel.textAlignment = NSTextAlignmentCenter;
    _usernameErrorLabel.textColor = [UIColor redColor];
    _usernameErrorLabel.font = [UIFont systemFontOfSize:13];
    [self.scrollView addSubview:_usernameErrorLabel];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:(BOOL)animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (IBAction)checkUser:(id)sender {
    if ([[_schoolEmail text] length] >= 3) {
        //Passed School email focus on getting username
        if (self.usernameIsUnique) {
            //passed username and email, focus on navigation
            BFTDataHandler *handler = [BFTDataHandler sharedInstance];
            [handler setInitialLogin:false];
            [self performSegueWithIdentifier:@"tomain" sender:self];
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
            self.initialUsername.layer.borderColor=[[UIColor redColor]CGColor];
            self.initialUsername.layer.borderWidth= 2.0f;
            [_usernameErrorLabel setText:@"Username Must Be Unique"];
        }
        else {
            [_usernameErrorLabel setText:@""];
            self.initialUsername.layer.borderWidth = 0.0f;
        }
    }] startConnection];
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
