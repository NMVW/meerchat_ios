//
//  BFTViewController.h
//  Bafit
//
//  Created by Keeano Martin on 7/18/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "BFTDataHandler.h"

@interface BFTViewController : UIViewController<UIAlertViewDelegate, FBLoginViewDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *PolicyButton;
@property (weak, nonatomic) IBOutlet FBLoginView *loginButton;
@property (strong, nonatomic) BFTDataHandler *data;
@property (strong, nonatomic) NSMutableArray *thumbURLS;

- (IBAction)PolicyAlert:(id)sender;
@end
