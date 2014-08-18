//
//  BFTEmailConfirmationViewController.h
//  Bafit
//
//  Created by Joseph Pecoraro on 8/13/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BFTEmailConfirmationViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *emailSentTextLabel;
@property (weak, nonatomic) IBOutlet UITextField *verificationNumberTextField;
@property (weak, nonatomic) IBOutlet UIButton *submitVerificationButton;


@end
