//
//  BFTCameraViewDelegate.h
//  Bafit
//
//  Created by Joseph Pecoraro on 10/28/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BFTCameraViewDelegate <NSObject>

-(void)recordingFinished;
-(void)recordingPaused;
-(void)recordingTimeFull;
-(void)receivedVideoName:(NSString*)videoName;
-(void)videoPostedToMain;
-(void)videoUploadedToNetwork;
-(void)videoSavedToDisk;
-(void)videoSentToUser;
-(void)imageUploaded;

-(void)videoUploadBegan;
-(void)videoUploadMadeProgress:(CGFloat)progress;

-(void)postingFailedWithError:(NSError*)error;

@end