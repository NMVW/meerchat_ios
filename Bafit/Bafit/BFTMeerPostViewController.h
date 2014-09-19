//
//  BFTMeerPostViewController.h
//  Bafit
//
//  Created by Keeano Martin on 8/21/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iCarousel.h"
#import "BFTDataHandler.h"
#import "BFTCameraView.h"

@interface BFTMeerPostViewController : UIViewController
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (strong, nonatomic) IBOutlet UIImageView *btmTrapazoid;
@property (strong, nonatomic) IBOutlet UILabel *userLabel;
@property (strong, nonatomic) IBOutlet UILabel *locationLabel;
@property (strong, nonatomic) UISwitch *anonymousSwitch;
@property (strong, nonatomic) UISwitch *locationSwitch;
@property (strong, nonatomic) BFTDataHandler *data;
@property (strong, nonatomic) IBOutlet UIView *recordView;
@property (strong, nonatomic) BFTCameraView *embeddedRecordView;

@end
