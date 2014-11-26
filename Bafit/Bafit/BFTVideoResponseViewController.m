//
//  BFTPostViewController.m
//  Bafit
//
//  Created by Keeano Martin on 8/3/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTVideoResponseViewController.h"
#import "BFTDataHandler.h"
#import "BFTCameraView.h"
#import "BFTVideoPlaybackController.h"
#import "BFTDatabaseRequest.h"
#import "BFTDataHandler.h"
#import "BFTPostHandler.h"
#import "BFTConstants.h"
#import "SVProgressHUD.h"
#import "BFTAppDelegate.h"

@interface BFTVideoResponseViewController ()

@end

#define CAPTURE_FRAMES_PER_SECOND 20

@implementation BFTVideoResponseViewController {
    BOOL _videoPosted;
    BOOL _thumbUploaded;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self getVideoName];
    
    //enable scroll view
    [_scrollView setScrollEnabled:YES];
    [_scrollView setScrollsToTop:YES];
    [_scrollView setContentSize:CGSizeMake([UIScreen mainScreen].bounds.size.width, 504)];
    
    //set Naivagtion for View
    [self.navigationBar setBarTintColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    [self.navigationBar setTranslucent:NO];
    UINavigationItem *navItem = [[UINavigationItem alloc] init];
  
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"milo_backtohome.png"] style:UIBarButtonItemStylePlain target:self action:@selector(popVC)];
    navItem.leftBarButtonItem = backButton;
    navItem.title = [NSString stringWithFormat:@"@%@", [self.postResponse BUN]];
    [self.navigationBar setItems:@[navItem]];
    [self.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil]];
    
    //set Data Handler for View
    [[BFTDataHandler sharedInstance] setPostView:NO];
    
    _embeddedrecordView = [[BFTCameraView alloc] initWithFrame:CGRectMake(0, 0, _recordView.frame.size.width, _recordView.frame.size.width)];
    _embeddedrecordView.maxDuration = 10.0;
    _embeddedrecordView.delegate = self;
    
    [_recordView addSubview:_embeddedrecordView];

    BFTVideoPlaybackController* videoPlayer = [[BFTVideoPlaybackController alloc] initWithVideoURL:[NSURL URLWithString:[self.postResponse videoURL]] andThumbURL:[NSURL URLWithString:[self.postResponse thumbURL]] frame:CGRectMake(0, 0, self.userVideoView.frame.size.width, self.userVideoView.frame.size.height)];
    UITapGestureRecognizer *tapToPlay = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playUserVideo)];
    [videoPlayer.view addGestureRecognizer:tapToPlay];
    [self.userVideoView addSubview:videoPlayer.view];
    self.videoFromMain = videoPlayer;
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

-(void)playUserVideo {
    [self.videoFromMain togglePlayback];
}

- (IBAction)backButtonPressed:(id)sender {
    [self popVC];
}

-(void)popVC {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)getVideoName {
    [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"registerVid.php?UIDr=%@&UIDp=%@", [[BFTDataHandler sharedInstance] UID], [self.postResponse UID]] completionBlock:^(NSMutableData *data, NSError *error) {
        if (!error) {
            NSArray *responseJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            for (NSDictionary *dict in responseJSON) {
                [[BFTDataHandler sharedInstance] setMp4Name:[dict objectForKey:@"FName"]];
                [[BFTPostHandler sharedInstance] setPostMC:[dict objectForKey:@"MC"]];
                [[BFTPostHandler sharedInstance] setPostFName:[dict objectForKey:@"FName"]];
                [[BFTPostHandler sharedInstance] setXmmpToUser:[self.postResponse BUN]];
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
    
    [((BFTAppDelegate*)[[UIApplication sharedApplication] delegate]) registerForNotifications];
}

@end
