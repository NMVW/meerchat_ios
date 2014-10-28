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

@interface BFTVideoResponseViewController ()

@end

#define CAPTURE_FRAMES_PER_SECOND 20

@implementation BFTVideoResponseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //Setup Navigation
    _customNavView = [[UIView alloc] init];
    [_customNavView setBackgroundColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    
    //enable scroll view
    [_scrollView setScrollEnabled:YES];
    [_scrollView setScrollsToTop:YES];
    [_scrollView setContentSize:CGSizeMake([UIScreen mainScreen].bounds.size.width, 504)];
//    [_scrollView setContentOffset:CGPointMake(0, 30) animated:YES];
    
    
    _FrontCamera = NO;
    self.replyURL = self.replyURL;
    //set Data Handler for View
    [[BFTDataHandler sharedInstance] setPostView:NO];
    BOOL test = [[BFTDataHandler sharedInstance] postView];
    NSLog(test ? @"YES" : @"NO");
    
    //Create output.
    _output = [[AVCaptureMovieFileOutput alloc] init];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    // Do any additional setup after loading the view.
//    if(!_replyURL){
//        //default video used incase URL is not sent
//        [self setReplyURL:@"http://bafit.mobi/userPosts/v2.mp4"];
//    }
    
//    //Setup reply record function
//    _embeddedrecordView = [[KZCameraView alloc] initWithFrame:_recordView.frame withVideoPreviewFrame:CGRectMake(0, 0, 275, 275)];
//    _embeddedrecordView.maxDuration = 10.0;
//    [_recordView addSubview:_embeddedrecordView];
    
    _embeddedrecordView = [[BFTCameraView alloc] initWithFrame:CGRectMake(0, 0, _recordView.frame.size.width, _recordView.frame.size.width)];
    _embeddedrecordView.maxDuration = 10.0;
//    _embeddedrecordView.delegate = self;
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
//    [_postToolBar setHidden:YES];
    
    [_postToolBar setBackgroundColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    //UIToolbar *recordToolbar = [[UIToolbar alloc] initWithFrame:_postToolBar.frame];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    
    NSLog(@"In Finish");
    
    [_player1 seekToTime:kCMTimeZero];
    if ([_playButton isHidden]) {
        [_playButton setHidden:NO];
    }
}


//-(void)longPressRecord:(UILongPressGestureRecognizer *)sender {
//    NSLog(@"Sender being called");
//    if ([sender isEqual:_recordGesture]) {
//        if (sender.state == UIGestureRecognizerStateBegan) {
//            NSLog(@"Recording should start");
//            [self initializeCamera];
//        }else{
//            NSLog(@"State was not started");
//        }
//    }
//}

//-(IBAction)saveVideo:(id)sender
//{
//    [_embeddedrecordView saveVideoWithCompletionBlock:^(BOOL success) {
//        if (success)
//        {
//            //Do something after video got succesfully saved
//        }
//    }];
//}

//- (IBAction)captureVideo:(id)sender {
//    [self initializeCamera];
//}

- (IBAction)playButtonPress:(id)sender {
    
    [_playButton setHidden:YES];
    [_player1 play];
}

-(void)popVC {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
