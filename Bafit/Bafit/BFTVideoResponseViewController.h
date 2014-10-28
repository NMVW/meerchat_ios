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


@interface BFTVideoResponseViewController : UIViewController <UIScrollViewDelegate, AVCaptureFileOutputRecordingDelegate, BFTCameraViewDelegate>
@property (strong, nonatomic) IBOutlet UIToolbar *bottomToolbar;
@property (strong, nonatomic) MPMoviePlayerController *player;
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (nonatomic) UIImagePickerController *picker;
@property (strong, nonatomic) IBOutlet UIView *userVideoView;
@property (strong, nonatomic) AVPlayer *player1;
@property (weak, nonatomic) NSString *replyURL;
@property (weak, nonatomic) NSString *userReply;
@property (strong, nonatomic) IBOutlet UIView *customNavView;
@property (strong, nonatomic) IBOutlet UIButton *customBackButton;
@property (strong, nonatomic) IBOutlet UITextField *userInput;
@property (strong, nonatomic) IBOutlet UIView *recordView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;



//AVFoundation Controls
@property BOOL FrontCamera;
@property (strong, nonatomic) AVCaptureMovieFileOutput *output;
@property (strong, nonatomic) IBOutlet UIToolbar *postToolBar;
@property (strong, nonatomic) BFTCameraView *embeddedrecordView;



- (IBAction)captureVideo:(id)sender;
- (IBAction)playButtonPress:(id)sender;

@end
