//
//  BFTCameraView.m
//  Bafit
//
//  Created by Keeano Martin on 9/10/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTCameraView.h"
#import "CaptureManager.h"
#import "AVCamRecorder.h"
#import "BFTDatabaseRequest.h"
#import "BFTDataHandler.h"
#import "BFTMainPostViewController.h"
#import "BFTCameraViewDelegate.h"
#import "BFTCaptureManagerDelegate.h"
#import "BFTConstants.h"

@interface BFTCameraView () <UIGestureRecognizerDelegate, BFTCaptureManagerDelegate>

@property (strong, nonatomic) UIView *videoPreviewView;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic, strong) UILabel *focusModeLabel;

//Exporting progress
@property (nonatomic,strong) UIView *progressView;
@property (nonatomic,strong) UIProgressView *progressBar;
@property (nonatomic,strong) UILabel *progressLabel;
@property (nonatomic,strong) UIActivityIndicatorView *activityView;

//Recording progress
//@property (nonatomic,strong) UIProgressView *durationProgressBar;
@property (nonatomic,assign) float duration;
@property (nonatomic,strong) NSTimer *durationTimer;

//Button to switch between back and front cameras
@property (nonatomic,strong) UIButton *camerasSwitchBtn;


//Buttons to preview video before upload
@property (strong, nonatomic) UIView *playPreviewVidView;

//@property (strong, nonatomic) BFTVideoPlaybackController* videoPlayer;

@property (assign) CGRect rect;

@end

@implementation BFTCameraView {
    BOOL _recordingTimeFull;
    
}

@synthesize durationProgressBar;

- (id)initWithFrame:(CGRect)frame fromView:(NSString *)view
{
    self = [super initWithFrame:frame];
    if (self) {
        if ([self captureManager] == nil) {
            
            // Add listener for post button action -- post button got moved to BFTMainPostViewController
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(postBtnClicked)
                                                         name:@"postBtnClicked"
                                                       object:nil];
            
            self.hasShownRecordBtn = NO;
            
            CaptureManager *manager = [[CaptureManager alloc] init];
            [self setCaptureManager:manager];
            [[self captureManager] setDelegate:self];
            
            if ([[self captureManager] setupSession]) {
                //creating preview layer and adding it to the UI
                AVCaptureVideoPreviewLayer *newCaptureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:[[self captureManager] session]];
                _videoPreviewView = [[UIView alloc] init];
                _videoPreviewView.frame = frame;
                
                
                CALayer *viewLayer = _videoPreviewView.layer;
                [viewLayer setMasksToBounds:YES];
                [self addSubview:_videoPreviewView];
                
                CGRect bounds = _videoPreviewView.bounds;
                [newCaptureVideoPreviewLayer setFrame:bounds];
                
                //Check if orientation video for allowed (portrait)
                if ([newCaptureVideoPreviewLayer.connection isVideoOrientationSupported]) {
                    [newCaptureVideoPreviewLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
                }
                
                [newCaptureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
                [viewLayer insertSublayer:newCaptureVideoPreviewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
                
                [self setCaptureVideoPreviewLayer:newCaptureVideoPreviewLayer];
                
                //start session Async
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [[[self captureManager] session] startRunning];
                });
                
                //Handle UIElements here
                //add button to handle long gesture press 95% of UIVIew frame // was 105
                _overlayButton = [[UIButton alloc] initWithFrame:CGRectMake(0, -5, _videoPreviewView.frame.size.width, _videoPreviewView.frame.size.height)];
                [_overlayButton setTitle:@"Hold to Record" forState:UIControlStateNormal];
                
                _overlayButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
                _overlayButton.contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
                [_overlayButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:1] forState:UIControlStateNormal];
                [_videoPreviewView addSubview:_overlayButton];
                
                //add UILongPressGesture to UIButton
                UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(startRecording:)];
                [longPress setDelegate:self];
                [_overlayButton addGestureRecognizer:longPress];
                
                //Camera Switch Button (top right corner)
                _camerasSwitchBtn = [[UIButton alloc] initWithFrame:CGRectMake(200, 5, 34, 25)];
                [_camerasSwitchBtn setBackgroundImage:[UIImage imageNamed:@"switchCameraNew.png"] forState:UIControlStateNormal];
                [_camerasSwitchBtn addTarget:self action:@selector(switchCamera) forControlEvents:UIControlEventTouchUpInside];
                [_videoPreviewView addSubview:_camerasSwitchBtn];
                
                // play button to preview video before upload
                _play = [[UIButton alloc] initWithFrame:CGRectMake(7, 7, 19, 25)];
                [_play setBackgroundImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
                [_play addTarget:self action:@selector(previewVideo:) forControlEvents:UIControlEventTouchUpInside];
                _play.hidden = YES;
                [_videoPreviewView addSubview:_play];
                
                // recording button to help indicate when user is in process of recording
                _recording = [[UIButton alloc] initWithFrame:CGRectMake(7, 7, 19, 25)];
                [_recording setBackgroundImage:[UIImage imageNamed:@"record1.png"] forState:UIControlStateNormal];
                [_recording addTarget:self action:@selector(previewVideo:) forControlEvents:UIControlEventTouchUpInside];
                _recording.hidden = YES;
                _recording.userInteractionEnabled = NO;
                [_videoPreviewView addSubview:_recording];
                
                _playPreviewVidView = [[UIView alloc] init];
                _playPreviewVidView.frame = frame;
                
                self.rect = bounds;
                CALayer *viewPreviewLayer = _playPreviewVidView.layer;
                [viewPreviewLayer setMasksToBounds:YES];
                [self addSubview:_playPreviewVidView];
                [self bringSubviewToFront:_videoPreviewView];
                _playPreviewVidView.hidden = YES;
                
                // play button to preview video before upload
                _pause = [[UIButton alloc] initWithFrame:CGRectMake(5, 5, 19, 25)];
                [_pause setBackgroundImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
                [_pause addTarget:self action:@selector(closePreview) forControlEvents:UIControlEventTouchUpInside];
                [_playPreviewVidView addSubview:_pause];
                
                //progresBar
                self.durationProgressBar = [[UIProgressView alloc] init];
                self.durationProgressBar.frame = CGRectMake(0, 545, 320, 44);
                self.durationProgressBar.trackTintColor = [UIColor whiteColor];
                [self.durationProgressBar setTintColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
                
                
                //fixes hidden elements on iphone 4 (480 screens) - poorly designed for the small screen when I (sam) started... this is a patch
                int height =  [[UIScreen mainScreen] bounds].size.height;
                if(height == 480)
                {
                    self.durationProgressBar.frame = CGRectMake(0, 457, 320, 44);
                    if([view isEqualToString:@"postView"])
                    {
                        self.durationProgressBar.frame = CGRectMake(0, 457, 320, 44);
                    }
                    
                    if([view isEqualToString:@"chatView"])
                    {
                        self.durationProgressBar.frame = CGRectMake(0, 393, 320, 44);
                    }
                }
                
                if([view isEqualToString:@"postView"] || [view isEqualToString:@"responseView"])
                {
                    self.durationProgressBar.frame = CGRectMake(0, 545, 320, 44);
                }
                
                if([view isEqualToString:@"chatView"])
                {
                    self.durationProgressBar.frame = CGRectMake(0, 481, 320, 44);
                }
                
                if(height == 480)
                {
                    self.durationProgressBar.frame = CGRectMake(0, 457, 320, 44);
                    if([view isEqualToString:@"postView"] || [view isEqualToString:@"responseView"])
                    {
                        self.durationProgressBar.frame = CGRectMake(0, 457, 320, 44);
                    }
                    
                    if([view isEqualToString:@"chatView"])
                    {
                        self.durationProgressBar.frame = CGRectMake(0, 393, 320, 44);
                    }
                    
                    if([view isEqualToString:@"postView"])
                    {
                        self.durationProgressBar.frame = CGRectMake(0, 457, 320, 44);
                    }
                    
                }
                
                
                CATransform3D transform = CATransform3DScale(self.durationProgressBar.layer.transform, 1.0f, 22.0f, 1.0f);
                self.durationProgressBar.layer.transform = transform;
                
                [self addSubview:self.durationProgressBar];
                
                self.fromView = view;
            }
        }
    }
    return self;
}

#pragma mark

-(void)previewVideo:(id)sender {
    
    _videoPreviewView.hidden = YES;
    _playPreviewVidView.hidden = NO;
    
    
    NSURL* localVidURL = [[self.captureManager recorder] outputFileURL];
    
    CALayer *viewPreviewLayer = _playPreviewVidView.layer;
    [viewPreviewLayer setMasksToBounds:YES];
    
    NSMutableArray* urlArray = [[NSMutableArray alloc] init];
    
    int i = 1;
    
    // stitch together all of the recording segments for full length preview playback
    for (AVAsset *asset in self.captureManager.assets)
    {
        if ([asset isKindOfClass:AVURLAsset.class])
        {
            AVURLAsset *urlAsset = (AVURLAsset*)asset;
            NSURL* fileURL = urlAsset.URL;
            AVPlayerItem *videoSegment = [AVPlayerItem playerItemWithURL: fileURL];
            
            //if is the last segment of recording send notification to hide preview playback when finished
            if (i == [self.captureManager.assets count])
            {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:videoSegment];
            }
            
            [urlArray addObject:videoSegment];
        }
        i++;
    }
    
    AVAsset *avAsset = [AVAsset assetWithURL:localVidURL];
    self.avPlayerItem =[[AVPlayerItem alloc] initWithAsset:avAsset];
    self.videoPlayer = [[AVQueuePlayer alloc] initWithItems:urlArray];
    self.playerLayer =[AVPlayerLayer playerLayerWithPlayer:self.videoPlayer];
    [self.playerLayer setFrame:self.rect];
    [self.playerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_playPreviewVidView.layer addSublayer:self.playerLayer];
    
    [_playPreviewVidView bringSubviewToFront:_pause];
    
    [self.videoPlayer play];
}

// Will be called when the Preview AVPlayer finishes playing -- hide preview video and show camera recording view again
-(void)itemDidFinishPlaying:(NSNotification *)notification {
    NSLog(@"Preview itemDidFinishPlaying");
    [self closePreview];
}

-(void)closePreview {
    [self.videoPlayer removeAllItems];
    _videoPreviewView.hidden = NO;
    _playPreviewVidView.hidden = YES;
}

// toggle record button for blinking effect when user is recording a video
-(void)blinkRecordBtn {
    
    if ([[self captureManager] recorder].recording && _play.hidden) {
        if (_recording.hidden)
        {
            _recording.hidden = NO;
        }
        else
        {
            _recording.hidden = YES;
        }
    }
}

- (IBAction)startRecording:(UILongPressGestureRecognizer*)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            NSLog(@"Recording Started");
            
            if (self.duration < self.maxDuration) {
                _play.hidden = YES;
                _recording.hidden = NO;
                
                // control the rate of blinking for record button
                if (!self.hasShownRecordBtn)
                {
                    self.hasShownRecordBtn = YES;
                    [NSTimer scheduledTimerWithTimeInterval:0.6 target:self selector:@selector(blinkRecordBtn) userInfo: nil repeats:YES];
                }
            }
            
            if (![[[self captureManager] recorder] isRecording]) {
                if (self.duration < self.maxDuration) {
                    
                    _camerasSwitchBtn.hidden = YES;
                    [[self captureManager] startRecording];
                    [_overlayButton setTitle:@"" forState:UIControlStateNormal];
                }
            }
            break;
        }
        case UIGestureRecognizerStateEnded: {
            NSLog(@"Recording Stopped");
            if ([[[self captureManager] recorder] isRecording]) {
                [self recordingFinished];
                [self.delegate showClearButton];
                _play.hidden = NO;
                _camerasSwitchBtn.hidden = NO;
                _recording.hidden = YES;
                
                if (self.duration < 5)
                {
                    [_overlayButton setTitle:@"Hold to Record More" forState:UIControlStateNormal];
                }
            }
            break;
        }
        default:
            break;
    }
}

-(void)postBtnClicked {
    self.durationProgressBar.hidden = YES;
    [self saveVideo];
}

-(void)saveVideo {
    if (![self.delegate canUploadVideo]) {
        return;
    }
    
    __block id weakSelf = self;
    [self.captureManager saveVideoWithCompletionBlock:^(BOOL success) {
        if (success) {
            NSLog(@"Video Saved To Disk");
            [weakSelf performSelector:@selector(refresh) withObject:nil afterDelay:0.5];
            [self.delegate videoSavedToDisk];
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"video unable to be saved, please contact support" delegate:self cancelButtonTitle:@"okay" otherButtonTitles: nil];
            [alert show];
            self.durationProgressBar.hidden = NO;
        }
    }];
}

- (void)removeTimeFromDuration:(float)removeTime; {
    self.duration = self.duration - removeTime;
    self.durationProgressBar.progress = self.duration/self.maxDuration;
}

-(void)switchCamera {
    [self.captureManager switchCamera];
}

-(void)refresh {
//    self.progressView.hidden = YES;
    self.duration = 0.0;
    self.durationProgressBar.progress = 0.0;
    [self.durationTimer invalidate];
    self.durationTimer = nil;
}

#pragma mark - BFT Capture Manager Delegate

-(BOOL)canStartRecording {
    NSLog(@"Can Start Recording: %i", !_recordingTimeFull);
    return !_recordingTimeFull;
}

-(void)updateProgress {
    self.duration = self.duration + 0.1;
    self.durationProgressBar.progress = self.duration/self.maxDuration;
    
    // notification to change Post Button color to white on post screens since progress bar is orange
    if (self.duration > 8.7f && self.duration < 9.1f)
    {
        [self.delegate changePostBtnColor];
    }
    
    //BFTMainPostViewController Can Post b/c recording is greater than 3 seconds
    //notification to change the post screens post buttons color after 3 secs of recording if canUploadVideo
    if (self.duration > 3.0f && self.duration < 3.1f)
    {
        [self.delegate recordingIsThreeSeconds];
    }
    
    // change Progress Bar color on to orange if greater than 3 seconds
    if (self.duration > 3.0f)
    {
        [self.durationProgressBar setTintColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    }
    else
    {
        [self.durationProgressBar setTintColor:[UIColor colorWithRed:204.0f/255.0f green:204.0f/255.0f blue:204.0f/255.0f alpha:1.0]];
    }
    
    //NSLog(@"self.duration %f, self.progressBar %f", self.duration, self.durationProgressBar.progress);
    if (self.duration >= self.maxDuration) {
        [self recordingTimeFull];
        [self recordingFinished];
        
        [self.delegate showClearButton];
        
        //recording duration full - hide recording indicator show play button
        _play.hidden = NO;
        _camerasSwitchBtn.hidden = NO;
        _recording.hidden = YES;
    }
}

-(void)removeProgress {
    self.progressBar.hidden = YES;
}

-(void)captureManager:(CaptureManager *)captureManager didFailWithError:(NSError *)error {
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                            message:[error localizedFailureReason]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"OK button title")
                                                  otherButtonTitles:nil];
        [alertView show];
    });
}

-(void)captureManagerRecordingBegan:(CaptureManager *)captureManager {
    _videoPreviewView.layer.borderColor = [UIColor whiteColor].CGColor;
    _videoPreviewView.layer.borderWidth = 2.0;
    //progress bar timer
    self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
}

-(void)captureManagerRecordingFinished:(CaptureManager *)captureManager {
    [self.delegate recordingFinished];
}

-(void)captureManagerDeviceConfigurationChanged:(CaptureManager *)captureManager {
    //Do something
}

-(void)recordingFinished {
    [self.durationTimer invalidate];
    [[self captureManager] stopRecording];
    self.videoPreviewView.layer.borderColor = [UIColor clearColor].CGColor;

    /*** old post button overlayed on video screen - used only on video response screen
    UIButton *saveButton = [[UIButton alloc] initWithFrame:CGRectMake(-10, 210, _videoPreviewView.frame.size.width, 30)];
    [saveButton setTitle:@"Post" forState:UIControlStateNormal];
    [saveButton addTarget:self action:@selector(saveVideo) forControlEvents:UIControlEventTouchUpInside];
    [_videoPreviewView addSubview:saveButton];
      ***/
    
    [self.delegate recordingFinished];
}

-(void)recordingPaused {
    [self.delegate recordingPaused];
}

-(void)recordingTimeFull {
    [self.delegate recordingTimeFull];
    _recordingTimeFull = YES;
}

-(void)receivedVideoName:(NSString*)videoName {
    [self.delegate receivedVideoName:videoName];
}

-(void)videoPostedToMain {
    [self.delegate videoPostedToMain];
}

-(void)videoSentToUser {
    [self.delegate videoSentToUser];
}

-(void)videoUploadedToNetwork {
    [self.delegate videoUploadedToNetwork];
}

-(void)videoSavedToDisk {
    [self.delegate videoSavedToDisk];
}

-(void)videoUploadBegan {
    [self.delegate videoUploadBegan];
}

-(void)imageUploaded {
    [self.delegate imageUploaded];
}

-(void)videoUploadMadeProgress:(CGFloat)progress {
    [self.delegate videoUploadMadeProgress:progress];
}

-(void)postingFailedWithError:(NSError*)error {
    [self.delegate postingFailedWithError:error];
}

@end

