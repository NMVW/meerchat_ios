//
//  BFTCaptureManagerDelegate.h
//  Bafit
//
//  Created by Joseph Pecoraro on 10/28/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BFTCaptureManagerDelegate <NSObject>

-(void)captureManager:(CaptureManager *)captureManager didFailWithError:(NSError *)error;
-(void)captureManagerRecordingBegan:(CaptureManager *)captureManager;
-(void)captureManagerRecordingFinished:(CaptureManager *)captureManager;

//Stuff I added
-(void)recordingFinished;
-(void)recordingPaused;
-(void)recordingTimeFull;
-(void)receivedVideoName:(NSString*)videoName;
-(void)videoPostedToMain;
-(void)videoUploadedToNetwork;
-(void)videoSavedToDisk;
-(void)videoSentToUser;

//Upload progress
-(void)videoUploadBegan;
-(void)videoUploadMadeProgress:(CGFloat)progress;

-(void)postingFailedWithError:(NSError*)error;

@optional
-(void)removeTimeFromDuration:(float)removeTime;
-(void)updateProgress;
-(void)removeProgress;

-(void)captureManagerStillImageCaptured:(CaptureManager *)captureManager;
-(void)captureManagerDeviceConfigurationChanged:(CaptureManager *)captureManager;

@end