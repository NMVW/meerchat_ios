//
//  BFTVideoMessageViewController.m
//  Bafit
//
//  Created by Joseph Pecoraro on 10/29/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTVideoMessageViewController.h"
#import "BFTDataHandler.h"
#import "BFTDatabaseRequest.h"
#import "BFTPostHandler.h"
#import "BFTConstants.h"
#import "SVProgressHUD.h"
@import AVFoundation;

@interface BFTVideoMessageViewController ()

@end

@implementation BFTVideoMessageViewController {
    BOOL _videoPosted;
    BOOL _thumbUploaded;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self getVideoName];
    
    self.canPost = NO;
    
    [self.navigationController.navigationBar setBarTintColor:kOrangeColor];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setTranslucent:NO];
    
    self.navigationItem.title = [NSString stringWithFormat:@"@%@", self.otherPersonsUserName];
    
    //set Data Handler for View
    [[BFTDataHandler sharedInstance] setPostView:NO];
    
    _embeddedrecordView = [[BFTCameraView alloc] initWithFrame:CGRectMake(0, 0, _recordView.frame.size.width, _recordView.frame.size.width) fromView:@"chatView"];
    _embeddedrecordView.maxDuration = 10.0;
    _embeddedrecordView.delegate = self;
    
    [_recordView addSubview:_embeddedrecordView];
    
    [self.view addSubview:_embeddedrecordView.durationProgressBar];
    [self.view bringSubviewToFront:_embeddedrecordView.durationProgressBar];
    
    [self.view bringSubviewToFront:self.postBtnView];
    [self.view bringSubviewToFront:self.clearBtn];
    self.clearBtn.hidden = YES;
    
    UIBarButtonItem *backBarBtn = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(popVC)];
    self.navigationItem.backBarButtonItem.tintColor = [UIColor whiteColor];
    self.navigationItem.backBarButtonItem = backBarBtn;
    
    self.navigationController.navigationBar.topItem.backBarButtonItem = backBarBtn;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

-(void)returnToMain {
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)popVC {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"removeSession" object:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)getVideoName {
    [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"registerVid.php?UIDr=%@&UIDp=%@", [[BFTDataHandler sharedInstance] UID], self.otherPersonsUserName] completionBlock:^(NSMutableData *data, NSError *error) {
        if (!error) {
            NSArray *responseJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            for (NSDictionary *dict in responseJSON) {
                [[BFTDataHandler sharedInstance] setMp4Name:[dict objectForKey:@"FName"]];
                [[BFTPostHandler sharedInstance] setPostMC:[dict objectForKey:@"MC"]];
                [[BFTPostHandler sharedInstance] setPostFName:[dict objectForKey:@"FName"]];
                [[BFTPostHandler sharedInstance] setXmmpToUser:self.otherPersonsUserName];
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

//notification to show clear button after recording complete
-(void)showClearButton {
    self.clearBtn.hidden = NO;
}

//notification to change the post buttons color if recording progress is greater than 88%
-(void)changePostBtnColor {
    
    [self.postBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

//notification to change the post buttons color after 3 secs of recording if canUploadVideo
-(void)recordingIsThreeSeconds {
    self.canPost = YES;
    
    [self.postBtn setTitleColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0] forState:UIControlStateNormal];
}

#pragma mark - Button Actions
- (IBAction)postBtnClicked:(id)sender {
    if ([self canUploadVideo])
    {
        if (self.canPost)
        {
            [self.postBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            _embeddedrecordView.durationProgressBar.hidden = YES;
            [_embeddedrecordView postBtnClicked];
        }
        else
        {
            _embeddedrecordView.durationProgressBar.hidden = NO;
            if (NSClassFromString(@"UIAlertController") != nil) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Please record a longer video" message:@"Video posts must be at least 3 seconds long." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                [alert addAction:defaultAction];
                
                [self presentViewController:alert animated:YES completion:nil];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Please record a longer video" message:@"Video posts must be at least 3 seconds long." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
            }
        }
    }
    else
    {
        _embeddedrecordView.durationProgressBar.hidden = NO;
    }
}

//refresh entire view delete recorded video
- (IBAction)clearBtnClicked:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"removeSession" object:nil];
    self.canPost = NO;
    
    [_embeddedrecordView removeFromSuperview];
    [_embeddedrecordView.durationProgressBar removeFromSuperview];
    
    _embeddedrecordView = [[BFTCameraView alloc] initWithFrame:CGRectMake(0, 0, _recordView.frame.size.width, _recordView.frame.size.width) fromView:@"postView"];
    _embeddedrecordView.maxDuration = 10.0;
    _embeddedrecordView.delegate = self;
    [_recordView addSubview:_embeddedrecordView];
    
    [self.view addSubview:_embeddedrecordView.durationProgressBar];
    [self.view bringSubviewToFront:_embeddedrecordView.durationProgressBar];
    
    [self.view bringSubviewToFront:self.postBtnView];
    [self.view bringSubviewToFront:self.clearBtn];
    self.clearBtn.hidden = YES;
    
    [self.postBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
}

//refresh record video view -- delete & re-add b/c AVCaptureSession is wiped out
///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)applicationDidBecomeActive:(NSNotification*) notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"removeSession" object:nil];
    self.canPost = NO;
    
    [_embeddedrecordView removeFromSuperview];
    [_embeddedrecordView.durationProgressBar removeFromSuperview];
    _embeddedrecordView = nil;
    
    _embeddedrecordView = [[BFTCameraView alloc] initWithFrame:CGRectMake(0, 0, _recordView.frame.size.width, _recordView.frame.size.width) fromView:@"postView"];
    _embeddedrecordView.maxDuration = 10.0;
    _embeddedrecordView.delegate = self;
    [_recordView addSubview:_embeddedrecordView];
    
    [self.view addSubview:_embeddedrecordView.durationProgressBar];
    [self.view bringSubviewToFront:_embeddedrecordView.durationProgressBar];
    
    [self.view bringSubviewToFront:self.postBtnView];
    [self.view bringSubviewToFront:self.clearBtn];
    self.clearBtn.hidden = YES;
    
    [self.postBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
}

- (void)viewWillDisappear:(BOOL)animated {
    // hide and close preview player -- otherwise would continue playing in background on next screen
    [_embeddedrecordView closePreview];
    
    //wipe out AVCaptureSession
    [[NSNotificationCenter defaultCenter] postNotificationName:@"removeSession" object:nil];
    [super viewWillDisappear:animated];
}

@end
