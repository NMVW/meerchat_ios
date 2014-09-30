//
//  BFTPostViewController.m
//  Bafit
//
//  Created by Keeano Martin on 8/3/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTPostViewController.h"
#import "BFTDataHandler.h"
#import "BFTCameraView.h"

@interface BFTPostViewController ()

@end

#define CAPTURE_FRAMES_PER_SECOND 20

@implementation BFTPostViewController

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
    [self registerForKeyboardNotifications];
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

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:(BOOL)animated];
    [self deregisterFromKeyboardNotifications];
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


-(void)longPressRecord:(UILongPressGestureRecognizer *)sender {
    NSLog(@"Sender being called");
    if ([sender isEqual:_recordGesture]) {
        if (sender.state == UIGestureRecognizerStateBegan) {
            NSLog(@"Recording should start");
            [self initializeCamera];
        }else{
            NSLog(@"State was not started");
        }
    }
}

//-(IBAction)saveVideo:(id)sender
//{
//    [_embeddedrecordView saveVideoWithCompletionBlock:^(BOOL success) {
//        if (success)
//        {
//            //Do something after video got succesfully saved
//        }
//    }];
//}

- (IBAction)captureVideo:(id)sender {
    [self initializeCamera];
}

- (IBAction)playButtonPress:(id)sender {
    
    [_playButton setHidden:YES];
    [_player1 play];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSLog(@"Enter Did Finsih Launching");
    NSString *videoURL = info[UIImagePickerControllerMediaURL];
    [picker dismissViewControllerAnimated:YES completion:NULL];
    _player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:videoURL]];
    [_player.view setFrame:_recordView.bounds];
    [_player prepareToPlay];
    [_player setShouldAutoplay:NO];
    _player.scalingMode = MPMovieScalingModeAspectFit;
    [_recordView addSubview:_player.view];
    
    
}

-(void)popVC {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//AVCaptureSession to show live video feed in view
- (void) initializeCamera {
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
	session.sessionPreset = AVCaptureSessionPresetMedium;
	AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
	captureVideoPreviewLayer.frame = _recordView.bounds;
	[_recordView.layer addSublayer:captureVideoPreviewLayer];
	
    UIView *view = _recordView;
    CALayer *viewLayer = [view layer];
    [viewLayer setMasksToBounds:YES];
    
    CGRect bounds = [view bounds];
    [captureVideoPreviewLayer setFrame:bounds];
    
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *frontCamera;
    AVCaptureDevice *backCamera;
    
    for (AVCaptureDevice *device in devices) {
        NSLog(@"Device name: %@", [device localizedName]);
        if ([device hasMediaType:AVMediaTypeVideo]) {
            if ([device position] == AVCaptureDevicePositionBack) {
                NSLog(@"Device position : back");
                backCamera = device;
            }
            else {
                NSLog(@"Device position : front");
                frontCamera = device;
            }
        }
    }
    
    if (!_FrontCamera) {
        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
        if (!input) {
            NSLog(@"ERROR: trying to open camera: %@", error);
        }
        [session addInput:input];
    }
    
    if (_FrontCamera) {
        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
        if (!input) {
            NSLog(@"ERROR: trying to open camera: %@", error);
        }
        [session addInput:input];
    }
    
    //ADD AUDIO INPUT
	NSLog(@"Adding audio input");
	AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
	NSError *error = nil;
	AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
	if (audioInput)
	{
		[session addInput:audioInput];
	}
    
    //Add capture output
    if ([session canAddOutput:_output]) {
        [session addOutput:_output];
    }else{
        NSLog(@"Was unable to add output for recording video");
    }
    
	[session startRunning];
}

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    
}

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    
}

//Keyboard start
- (void)registerForKeyboardNotifications {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
}

- (void)deregisterFromKeyboardNotifications {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidHideNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    
}

- (void)keyboardWasShown:(NSNotification *)notification {
    
    NSDictionary* info = [notification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    CGPoint buttonOrigin = _bottomToolbar.frame.origin;
    CGFloat buttonHeight = _bottomToolbar.frame.size.height;
    CGRect visibleRect = self.view.frame;
    visibleRect.size.height -= keyboardSize.height;
    
    if (!CGRectContainsPoint(visibleRect, buttonOrigin)){
        
        CGPoint scrollPoint = CGPointMake(0.0, buttonOrigin.y - visibleRect.size.height + buttonHeight);
        
        //[_scrollView setContentOffset:scrollPoint animated:YES];
        
    }
    
}

- (void)keyboardWillBeHidden:(NSNotification *)notification {
    
    //[_scrollView setContentOffset:CGPointZero animated:YES];
    
}
//keyboard end

@end
