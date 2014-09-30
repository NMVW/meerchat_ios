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

@interface BFTCameraView () <UIGestureRecognizerDelegate>

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

@interface BFTCameraView (CaptureManagerDelegate) <CaptureManagerDelegate>
@end

@implementation BFTCameraView

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
            NSLog(@"START");
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
                [self.durationTimer invalidate];
                [[self captureManager] stopRecording];
                self.videoPreviewView.layer.borderColor = [UIColor clearColor].CGColor;
                UIButton *saveButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, _videoPreviewView.frame.size.width, 30)];
                [saveButton setTitle:@"Save" forState:UIControlStateNormal];
                [saveButton addTarget:self
                           action:@selector(saveVideo:)
                 forControlEvents:UIControlEventTouchUpInside];
                
                
                [_videoPreviewView addSubview:saveButton];
                NSLog(@"END number of pieces %lu", (unsigned long)[self.captureManager.assets count]);
            }
            break;
        }
        default:
            break;
    }
}


//- (void)saveVideoWithCompletionBlock:(void(^)(BOOL success))completion {

-(IBAction)saveVideo:(id)sender
{
     __block id weakSelf = self;
    [self.captureManager saveVideoWithCompletionBlock:^(BOOL success) {
       
        if (success)
        {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Test" message:@"video saved to photo album" delegate:self cancelButtonTitle:@"okay" otherButtonTitles: nil];
//            [alert show];
            
            [weakSelf performSelector:@selector(refresh) withObject:nil afterDelay:0.5];
            NSLog(@"Save Success");
            
        
            
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Test Error" message:@"video unable to be saved" delegate:self cancelButtonTitle:@"okay" otherButtonTitles: nil];
            [alert show];
        }
        
        if (success == YES) {
            NSLog(@"Navigate to main view");       }
    }];
    
}

-(void)refresh
{
//    self.progressView.hidden = YES;
    self.duration = 0.0;
//    self.durationProgressBar.progress = 0.0;
    [self.durationTimer invalidate];
    self.durationTimer = nil;
}



@end

@implementation BFTCameraView (CaptureManagerDelegate)

- (void) updateProgress
{
    self.progressView.hidden = NO;
    self.progressBar.hidden = NO;
    self.activityView.hidden = YES;
    self.progressLabel.text = @"Creating the video";
    self.progressBar.progress = self.captureManager.exportSession.progress;
    if (self.progressBar.progress > .99) {
        [self.captureManager.exportProgressBarTimer invalidate];
        self.captureManager.exportProgressBarTimer = nil;
    }
}

- (void) removeProgress
{
    self.progressBar.hidden = YES;
    [self.activityView startAnimating];
    self.progressLabel.text = @"Saving to Camera Roll";
}

- (void)captureManager:(CaptureManager *)captureManager didFailWithError:(NSError *)error
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                            message:[error localizedFailureReason]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"OK button title")
                                                  otherButtonTitles:nil];
        [alertView show];
    });
}

- (void)captureManagerRecordingBegan:(CaptureManager *)captureManager
{
    _videoPreviewView.layer.borderColor = [UIColor whiteColor].CGColor;
    _videoPreviewView.layer.borderWidth = 2.0;
}

- (void)captureManagerRecordingFinished:(CaptureManager *)captureManager
{
    NSLog(@"Recording finsihed called");
}

- (void)captureManagerDeviceConfigurationChanged:(CaptureManager *)captureManager
{
    //Do something
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
