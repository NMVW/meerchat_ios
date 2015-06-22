//
//  BFTCameraView.h
//  Bafit
//
//  Created by Keeano Martin on 9/10/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <UIKit/UIKit.h>
@import AVFoundation;

@class CaptureManager, AVCamPreviewView, AVCaptureVideoPreviewLayer;

@protocol BFTCameraViewDelegate;

@interface BFTCameraView : UIView

@property (nonatomic,weak) id<BFTCameraViewDelegate> delegate;
@property (nonatomic, assign) float maxDuration;
@property (nonatomic, strong) CaptureManager *captureManager;

//Buttons to preview video before upload
@property (nonatomic,strong) UIButton *play;
@property (nonatomic,strong) UIButton *pause;
@property (nonatomic,strong) UIButton *recording;

// Controls that need to be accessed by BFTMainPostViewController
@property (nonatomic,strong) UIProgressView *durationProgressBar;
@property (nonatomic, strong) UIButton *overlayButton;

@property (nonatomic, strong) AVQueuePlayer *videoPlayer;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayerItem *avPlayerItem;

//determines which view is using this either post view, chat view or response view to position progress bar depending on the view
@property (nonatomic, strong) NSString *fromView;

-(void)postBtnClicked;
-(void)closePreview;
- (IBAction)startRecording:(UILongPressGestureRecognizer*)recognizer;

// control the rate of blinking for record button
@property (nonatomic) BOOL hasShownRecordBtn;


// initial view with name of parent view to position progress bar depending on the view
- (id)initWithFrame:(CGRect)frame fromView:(NSString *)view;

@end

