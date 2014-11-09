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
@property (nonatomic, strong) UIButton *overlayButton;

//Exporting progress
@property (nonatomic,strong) UIView *progressView;
@property (nonatomic,strong) UIProgressView *progressBar;
@property (nonatomic,strong) UILabel *progressLabel;
@property (nonatomic,strong) UIActivityIndicatorView *activityView;

//Recording progress
@property (nonatomic,strong) UIProgressView *durationProgressBar;
@property (nonatomic,assign) float duration;
@property (nonatomic,strong) NSTimer *durationTimer;

//Button to switch between back and front cameras
@property (nonatomic,strong) UIButton *camerasSwitchBtn;

@end

@implementation BFTCameraView {
    BOOL _recordingTimeFull;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        if ([self captureManager] == nil) {
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
                //add button to handle long gesture press 95% of UIVIew frame
                _overlayButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, _videoPreviewView.frame.size.width, _videoPreviewView.frame.size.height)];
                [_overlayButton setTitle:@"Hold to Record" forState:UIControlStateNormal];
                [_overlayButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:1] forState:UIControlStateNormal];
                [_videoPreviewView addSubview:_overlayButton];
                //add UILongPressGesture to UIButton
                UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(startRecording:)];
                [longPress setDelegate:self];
                [_overlayButton addGestureRecognizer:longPress];
                //Camera Switch Button (top right corner)
                _camerasSwitchBtn = [[UIButton alloc] initWithFrame:CGRectMake(200, 0, _videoPreviewView.frame.size.width - 200, 20)];
                [_camerasSwitchBtn setBackgroundImage:[UIImage imageNamed:@"switchCamera.png"] forState:UIControlStateNormal];
                [_camerasSwitchBtn addTarget:self action:@selector(switchCamera) forControlEvents:UIControlEventTouchUpInside];
                [_videoPreviewView addSubview:_camerasSwitchBtn];
                
                //progresBar
                self.durationProgressBar = [[UIProgressView alloc] initWithFrame:CGRectMake(0, _videoPreviewView.frame.origin.y + _videoPreviewView.frame.size.height, _videoPreviewView.frame.size.width, 2)];
                [self.durationProgressBar setTintColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
                [self addSubview:self.durationProgressBar];
            }
        }
    }
    return self;
}

#pragma mark

- (IBAction)startRecording:(UILongPressGestureRecognizer*)recognizer
{
    switch (recognizer.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            NSLog(@"Recording Started");
            if (![[[self captureManager] recorder] isRecording])
            {
                if (self.duration < self.maxDuration)
                {
                    [[self captureManager] startRecording];
                    [_overlayButton setTitle:@"" forState:UIControlStateNormal];
                }
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            if ([[[self captureManager] recorder] isRecording])
            {
                [self recordingFinished];
            }
            break;
        }
        default:
            break;
    }
}

-(IBAction)saveVideo:(id)sender {
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
    //NSLog(@"self.duration %f, self.progressBar %f", self.duration, self.durationProgressBar.progress);
    if (self.durationProgressBar.progress > .99) {
        [self recordingTimeFull];
        [self recordingFinished];
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
    UIButton *saveButton = [[UIButton alloc] initWithFrame:CGRectMake(-10, 210, _videoPreviewView.frame.size.width, 30)];
    [saveButton setTitle:@"Post" forState:UIControlStateNormal];
    [saveButton addTarget:self action:@selector(saveVideo:) forControlEvents:UIControlEventTouchUpInside];
    
    [_videoPreviewView addSubview:saveButton];
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

