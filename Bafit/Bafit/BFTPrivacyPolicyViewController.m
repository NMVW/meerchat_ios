//
//  BFTPrivacyPolicyViewController.m
//  Bafit
//
//  Created by Keeano Martin on 8/24/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTPrivacyPolicyViewController.h"
#import "BFTDataHandler.h"
#import "BFTConstants.h"

@interface BFTPrivacyPolicyViewController ()

@end

@implementation BFTPrivacyPolicyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINavigationController *navController = self.navigationController;
    
    navController.navigationBar.translucent = NO;
    
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(dismissModally)];
    [self.navigationItem setLeftBarButtonItem:back];
}

-(void)dismissModally {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
