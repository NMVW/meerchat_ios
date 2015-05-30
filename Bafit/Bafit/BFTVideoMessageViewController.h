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
@protocol BFTCameraViewDelegate;

@interface BFTVideoMessageViewController : UIViewController <BFTCameraViewDelegate>

@property (nonatomic, copy) NSString *otherPersonsUserID;
@property (nonatomic, copy) NSString *otherPersonsUserName;
@property (strong, nonatomic) IBOutlet UIView *recordView;

@property (strong, nonatomic) BFTCameraView *embeddedrecordView;

@property (strong, nonatomic) IBOutlet UIView *postBtnView;
@property (strong, nonatomic) IBOutlet UIButton *postBtn;
@property (strong, nonatomic) IBOutlet UIButton *clearBtn;

@property (nonatomic) BOOL canPost;

@end
