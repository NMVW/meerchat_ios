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


@interface BFTPostViewController : UIViewController <UIImagePickerControllerDelegate, UIScrollViewDelegate, AVCaptureFileOutputRecordingDelegate>
@property (strong, nonatomic) IBOutlet UIToolbar *bottomToolbar;
@property (strong, nonatomic) MPMoviePlayerController *player;
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (nonatomic) UIImagePickerController *picker;
@property (strong, nonatomic) IBOutlet UIView *userVideoView;
@property (strong, nonatomic) IBOutlet UIView *recordView;
@property (strong, nonatomic) AVPlayer *player1;
@property (weak, nonatomic) NSString *replyURL;
@property (strong, nonatomic) IBOutlet UILabel *recordDescription;

//AVFoundation Controls
@property BOOL FrontCamera;
@property (strong, nonatomic) AVCaptureMovieFileOutput *output;
@property (strong, nonatomic) IBOutlet UIToolbar *postToolBar;



- (IBAction)captureVideo:(id)sender;
- (IBAction)playButtonPress:(id)sender;

@end
