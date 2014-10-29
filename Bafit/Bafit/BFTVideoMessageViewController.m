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
@import AVFoundation;

@interface BFTVideoMessageViewController ()

@end

@implementation BFTVideoMessageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self getVideoName];
    
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    [self.navigationController.navigationBar setTranslucent:NO];
    
    self.navigationItem.title = [NSString stringWithFormat:@"@%@", self.otherPersonsUserName];
    
    //set Data Handler for View
    [[BFTDataHandler sharedInstance] setPostView:NO];
    
    _embeddedrecordView = [[BFTCameraView alloc] initWithFrame:CGRectMake(0, 0, _recordView.frame.size.width, _recordView.frame.size.width)];
    _embeddedrecordView.maxDuration = 10.0;
    _embeddedrecordView.delegate = self;
    
    [_recordView addSubview:_embeddedrecordView];
}

-(void)returnToMain {
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)popVC {
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

-(void)videoUploadedToNetwork {
    NSLog(@"Video Uploaded To Network");
    [self popVC];
}

-(void)videoSavedToDisk {
    NSLog(@"Video Saved To Disk");
}

@end
