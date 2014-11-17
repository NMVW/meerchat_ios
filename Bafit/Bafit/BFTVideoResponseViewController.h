//
//  BFTPostViewController.h
//  Bafit
//
//  Created by Keeano Martin on 8/3/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "BFTCameraView.h"
#import "BFTCameraViewDelegate.h"
#import "BFTVideoPost.h"

@interface BFTVideoResponseViewController : UIViewController <UIScrollViewDelegate, BFTCameraViewDelegate>
@property (strong, nonatomic) MPMoviePlayerController *player;
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (nonatomic) UIImagePickerController *picker;
@property (strong, nonatomic) IBOutlet UIView *userVideoView;
@property (strong, nonatomic) AVPlayer *player1;

@property (nonatomic, strong) BFTVideoPost *postResponse;

@property (strong, nonatomic) IBOutlet UIView *customNavView;
@property (strong, nonatomic) IBOutlet UIButton *customBackButton;
@property (strong, nonatomic) IBOutlet UITextField *userInput;
@property (strong, nonatomic) IBOutlet UIView *recordView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

//AVFoundation Controls
@property BOOL FrontCamera;
@property (strong, nonatomic) AVCaptureMovieFileOutput *output;
@property (strong, nonatomic) BFTCameraView *embeddedrecordView;

- (IBAction)playButtonPress:(id)sender;

@end
