//
//  BFTInitialLoginViewController.m
//  Bafit
//
//  Created by Keeano Martin on 7/27/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTInitialLoginViewController.h"
#import "BFTDataHandler.h"

@interface BFTInitialLoginViewController ()

@end

@implementation BFTInitialLoginViewController

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
    // Do any additional setup after loading the view.
    [self registerForKeyboardNotifications];
    _initialUsername.delegate = self;
    _schoolEmail.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:(BOOL)animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self deregisterFromKeyboardNotifications];
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

- (IBAction)checkUser:(id)sender {
    //NSLog(@"Initial Login: %@",[[BFTDataHandler sharedInstance] initialLogin]);
    if ([[_schoolEmail text] length] >= 3) {
        //Passed School email focus on getting username
        if ([[_initialUsername text]length] >= 3) {
            //passed username and email, focus on navigation
            BFTDataHandler *handler = [BFTDataHandler sharedInstance];
            [handler setInitialLogin:false];
            [self performSegueWithIdentifier:@"tomain" sender:self];
        }else{
            //username incorrect
        }
    }else {
        //email incorrect
    }
}

//Keyboard start

- (void)registerForKeyboardNotifications {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
}

- (void)deregisterFromKeyboardNotifications {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidHideNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    
}

- (void)keyboardWasShown:(NSNotification *)notification {
    
    NSDictionary* info = [notification userInfo];
    
}

- (void)keyboardWillBeHidden:(NSNotification *)notification {
    
    [self.scrollView setContentOffset:CGPointZero animated:YES];
    
}

//keyboard end

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    NSLog(@"Getting Return");
    [_schoolEmail resignFirstResponder];
    return NO;
}


- (IBAction)editr:(id)sender {
    [sender resignFirstResponder];
}

- (IBAction)editreturn:(id)sender {
    [sender resignFirstResponder];
}

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
@end
