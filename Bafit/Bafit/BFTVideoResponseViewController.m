//
//  BFTPostViewController.m
//  Bafit
//
//  Created by Keeano Martin on 8/3/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTVideoResponseViewController.h"
#import "BFTDataHandler.h"
#import "BFTCameraView.h"
#import "BFTVideoPlaybackController.h"
#import "BFTDatabaseRequest.h"
#import "BFTDataHandler.h"
#import "BFTPostHandler.h"
#import "BFTConstants.h"
#import "SVProgressHUD.h"

@interface BFTVideoResponseViewController ()

@end

#define CAPTURE_FRAMES_PER_SECOND 20

@implementation BFTVideoResponseViewController {
    BOOL _videoPosted;
    BOOL _thumbUploaded;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self getVideoName];
    
    //Setup Navigation
    _customNavView = [[UIView alloc] init];
    [_customNavView setBackgroundColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    
    //enable scroll view
    [_scrollView setScrollEnabled:YES];
    [_scrollView setScrollsToTop:YES];
    [_scrollView setContentSize:CGSizeMake([UIScreen mainScreen].bounds.size.width, 504)];
    
    _FrontCamera = NO;
    self.replyURL = self.replyURL;
    
    //set Data Handler for View
    [[BFTDataHandler sharedInstance] setPostView:NO];
    
    //Create output.
    _output = [[AVCaptureMovieFileOutput alloc] init];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    // Do any additional setup after loading the view.
//    if(!_replyURL){
//        //default video used incase URL is not sent
//        [self setReplyURL:@"http://bafit.mobi/userPosts/v2.mp4"];
//    }
    
    _embeddedrecordView = [[BFTCameraView alloc] initWithFrame:CGRectMake(0, 0, _recordView.frame.size.width, _recordView.frame.size.width)];
    _embeddedrecordView.maxDuration = 10.0;
    _embeddedrecordView.delegate = self;
    
    [_recordView addSubview:_embeddedrecordView];
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:self.replyURL] options:nil];
        //AV Asset Player
        AVPlayerItem * playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
        _player1 = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player1];
    playerLayer.frame = _userVideoView.bounds;
        [_userVideoView.layer addSublayer:playerLayer];
        [_player1 seekToTime:kCMTimeZero];
    [_userVideoView addSubview:_playButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification
object:_player1];

    
}

-(void)returnToMain {
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:(BOOL)animated];
    [_customNavView setBackgroundColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    NSLog(@"In Finish");
    [_player1 seekToTime:kCMTimeZero];
    if ([_playButton isHidden]) {
        [_playButton setHidden:NO];
    }
}

- (IBAction)playButtonPress:(id)sender {
    [_playButton setHidden:YES];
    [_player1 play];
}

-(void)popVC {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtonPressed:(id)sender {
    [self popVC];
}

-(void)getVideoName {
    [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"registerVid.php?UIDr=%@&UIDp=%@", [[BFTDataHandler sharedInstance] UID], self.userReply] completionBlock:^(NSMutableData *data, NSError *error) {
        if (!error) {
            NSArray *responseJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            for (NSDictionary *dict in responseJSON) {
                [[BFTDataHandler sharedInstance] setMp4Name:[dict objectForKey:@"FName"]];
                [[BFTPostHandler sharedInstance] setPostMC:[dict objectForKey:@"MC"]];
                [[BFTPostHandler sharedInstance] setPostFName:[dict objectForKey:@"FName"]];
                [[BFTPostHandler sharedInstance] setXmmpToUser:self.userReply];
            }
        }else{
            NSLog(@"No Data recived for file type");
        }
    }] startConnection];
    //while here set the Username
    [[BFTPostHandler sharedInstance] setPostAT_Tag:[[BFTDataHandler sharedInstance] BUN]];
    NSLog(@"%@", [[BFTDataHandler sharedInstance] mp4Name]);
}

#pragma mark - BFTCameraViewDelegate

-(BOOL)canUploadVideo {
    return YES;
}

-(void)recordingFinished {
    NSLog(@"Recording Finished");
}

-(void)recordingPaused {
    NSLog(@"Recording Paused");
}

-(void)recordingTimeFull {
    NSLog(@"Recording Time Full");
}

-(void)receivedVideoName:(NSString*)videoName {
    NSLog(@"Received Video Name");
}

-(void)videoPostedToMain {
    NSLog(@"Video Posted To Main");
}

-(void)videoSentToUser {
    NSLog(@"Video Sent To User");
    _videoPosted = YES;
    if (_thumbUploaded && _videoPosted) {
        [self everythingFinished];
    }
}

-(void)videoUploadedToNetwork {
    NSLog(@"Video Uploaded To Network");
}

-(void)videoSavedToDisk {
    NSLog(@"Video Saved To Disk");
}

-(void)imageUploaded {
    _thumbUploaded = YES;
    if (_thumbUploaded && _videoPosted) {
        [self everythingFinished];
    }
}

-(void)videoUploadBegan {
    [SVProgressHUD showWithStatus:@"Saving Video" maskType:SVProgressHUDMaskTypeGradient];
}

-(void)videoUploadMadeProgress:(CGFloat)progress {
    [SVProgressHUD showProgress:progress status:@"Uploading Video to Server..." maskType:SVProgressHUDMaskTypeGradient];
}

-(void)postingFailedWithError:(NSError *)error {
    NSLog(@"Video Message Not Uploaded: %@\n%@", error.localizedDescription, [error.userInfo objectForKey:NSUnderlyingErrorKey]);
    [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    [self popVC];
}

-(void)everythingFinished {
    [SVProgressHUD dismiss];
    [self popVC];
}

@end
