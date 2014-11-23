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
#import "BFTVideoPlaybackController.h"

@interface BFTVideoResponseViewController : UIViewController <UIScrollViewDelegate, BFTCameraViewDelegate, UINavigationBarDelegate>

@property (strong, nonatomic) IBOutlet UIView *userVideoView;

@property (nonatomic, strong) BFTVideoPost *postResponse;

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;

@property (strong, nonatomic) IBOutlet UIView *recordView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) BFTCameraView *embeddedrecordView;
@property (nonatomic, strong) BFTVideoPlaybackController *videoFromMain;

@end
