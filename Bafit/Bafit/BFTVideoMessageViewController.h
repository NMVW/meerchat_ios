//
//  BFTVideoMessageViewController.h
//  Bafit
//
//  Created by Joseph Pecoraro on 10/29/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFTCameraView.h"
#import "BFTCameraViewDelegate.h"

@import AVFoundation;

@interface BFTVideoMessageViewController : UIViewController <BFTCameraViewDelegate>

@property (nonatomic, copy) NSString *otherPersonsUserID;
@property (nonatomic, copy) NSString *otherPersonsUserName;
@property (strong, nonatomic) IBOutlet UIView *recordView;

@property (strong, nonatomic) BFTCameraView *embeddedrecordView;

@end
