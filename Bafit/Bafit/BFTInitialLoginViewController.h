//
//  BFTInitialLoginViewController.h
//  Bafit
//
//  Created by Keeano Martin on 7/27/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BFTInitialLoginViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *schoolEmail;
@property (weak, nonatomic) IBOutlet UITextField *initialUsername;
@property (weak, nonatomic) IBOutlet UIButton *checkMark;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

-(IBAction)checkUser:(id)sender;
- (IBAction)editr:(id)sender;
- (IBAction)editreturn:(id)sender;

@end
