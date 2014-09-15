//
//  BFTCameraView.h
//  Bafit
//
//  Created by Keeano Martin on 9/10/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CaptureManager, AVCamPreviewView, AVCaptureVideoPreviewLayer;

@interface BFTCameraView : UIView

@property (nonatomic, assign) float maxDuration;
@property (nonatomic, strong) CaptureManager *captureManager;

@end
