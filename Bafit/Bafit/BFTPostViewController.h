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


@interface BFTPostViewController : UIViewController <UIImagePickerControllerDelegate, UIScrollViewDelegate>
@property (strong, nonatomic) IBOutlet UIToolbar *bottomToolbar;
@property (strong, nonatomic) MPMoviePlayerController *player;
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (nonatomic) UIImagePickerController *picker;
@property (strong, nonatomic) IBOutlet UIView *userVideoView;
@property (strong, nonatomic) IBOutlet UIView *recordView;
@property (strong, nonatomic) AVPlayer *player1;
@property (weak, nonatomic) NSString *replyURL;

//AVFoundation Controls
@property BOOL frontCamera;
@property (weak, nonatomic) IBOutlet UISegmentedControl *camerCheck;



- (IBAction)captureVideo:(id)sender;
- (IBAction)playButtonPress:(id)sender;

@end
