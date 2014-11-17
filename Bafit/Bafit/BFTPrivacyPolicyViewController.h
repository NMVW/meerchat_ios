//
//  BFTPrivacyPolicyViewController.h
//  Bafit
//
//  Created by Keeano Martin on 8/24/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BFTPrivacyPolicyViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIWebView *privacyWebView;

- (IBAction)acceptButton:(id)sender;
- (IBAction)declineButton:(id)sender;

@end
