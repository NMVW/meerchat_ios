//
//  BFTInitialLoginViewController.h
//  Bafit
//
//  Created by Keeano Martin on 7/27/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BFTInitialLoginViewController : UIViewController <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *schoolEmail;
@property (weak, nonatomic) IBOutlet UITextField *initialUsername;
@property (weak, nonatomic) IBOutlet UIButton *checkMark;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UILabel *usernameErrorLabel;

@property (assign) BOOL usernameIsUnique;
@property (assign) BOOL usernameNeedsUpdating;
@property (assign) BOOL couldNotConnect;

-(BOOL)textFieldShouldReturn:(UITextField *)textField;

- (IBAction)checkUser:(id)sender;
- (IBAction)editr:(id)sender;
- (IBAction)editreturn:(id)sender;
- (IBAction)didBeginEdit:(id)sender;

@end
