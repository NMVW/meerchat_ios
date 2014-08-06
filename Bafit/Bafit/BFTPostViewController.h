//
//  BFTPostViewController.h
//  Bafit
//
//  Created by Keeano Martin on 8/3/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Foundation/Foundation.h>
#import <MobileCoreServices/MobileCoreServices.h>


@interface BFTPostViewController : UIViewController <UIImagePickerControllerDelegate>
@property (strong, nonatomic) IBOutlet UIToolbar *bottomToolbar;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIView *recordView;
@property (strong, nonatomic) MPMoviePlayerController *player;
@property (strong, nonatomic) IBOutlet UIButton *recordButton;
@property (nonatomic) UIImagePickerController *picker;


- (IBAction)captureVideo:(id)sender;

@end
