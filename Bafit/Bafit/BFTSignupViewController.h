//
//  BFTInitialLoginViewController.h
//  Bafit
//
//  Created by Keeano Martin on 7/27/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BFTSignupViewController : UIViewController <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *schoolEmail;
@property (weak, nonatomic) IBOutlet UITextField *initialUsername;
@property (weak, nonatomic) IBOutlet UIButton *checkMark;
@property (strong, nonatomic) UILabel *usernameErrorLabel;

@property (strong, nonatomic) IBOutlet UIControl *bgControl;

@property (assign) BOOL usernameIsUnique;
@property (assign) BOOL usernameNeedsUpdating;
@property (assign) BOOL couldNotConnect;

@property (strong, nonatomic) IBOutlet UIButton *nextBtn;

-(BOOL)textFieldShouldReturn:(UITextField *)textField;

- (IBAction)checkUser:(id)sender;
- (IBAction)editr:(id)sender;
- (IBAction)editreturn:(id)sender;
- (IBAction)backgroundTapped:(id)sender;
- (IBAction)goBack:(id)sender;

@end
