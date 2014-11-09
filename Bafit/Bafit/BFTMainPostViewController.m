//
//  BFTMeerPostViewController.m
//  Bafit
//
//  Created by Keeano Martin on 8/21/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTMainPostViewController.h"
#import "BFTDataHandler.h"
#import "BFTPostHandler.h"
#import "BFTDatabaseRequest.h"
#import "CaptureManager.h"
#import "BFTConstants.h"
#import "SVProgressHUD.h"

@interface BFTMainPostViewController ()

@end

@implementation BFTMainPostViewController {
    BOOL _videoPosted;
    BOOL _thumbUploaded;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    //Set Data Handler for Post View
    [[BFTDataHandler sharedInstance] setPostView:YES];
    
    [[BFTPostHandler sharedInstance] setPostCategory:0];

    [self getVideoName];
    
    //set Naivagtion for View
    [self.navigationBar setBarTintColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    [self.navigationBar setTranslucent:NO];
    UINavigationItem *navItem = [[UINavigationItem alloc] init];
    navItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"post_center.png"]];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"milo_backtohome.png"] style:UIBarButtonItemStylePlain target:self action:@selector(popVC)];
    navItem.leftBarButtonItem = backButton;
    [self.navigationBar setItems:@[navItem]];
    
    //setup post view record
    //Setup reply record function
    _embeddedRecordView = [[BFTCameraView alloc] initWithFrame:CGRectMake(0, 0, _recordView.frame.size.width, _recordView.frame.size.width)];
    _embeddedRecordView.maxDuration = 10.0;
    _embeddedRecordView.delegate = self;
    [_recordView addSubview:_embeddedRecordView];
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

-(void)getVideoName {
    [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"registerVid.php?UIDr=%@&UIDp=%@", [[BFTDataHandler sharedInstance] UID], [[BFTDataHandler sharedInstance] UID]] completionBlock:^(NSMutableData *data, NSError *error) {
        if (!error) {
            NSArray *responseJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            for (NSDictionary *dict in responseJSON) {
                [[BFTDataHandler sharedInstance] setMp4Name:[dict objectForKey:@"FName"]];
                [[BFTPostHandler sharedInstance] setPostMC:[dict objectForKey:@"MC"]];
                [[BFTPostHandler sharedInstance] setPostFName:[dict objectForKey:@"FName"]];
            }
        }else{
            NSLog(@"No Data recived for file type");
        }
    }] startConnection];
    //while here set the Username
    [[BFTPostHandler sharedInstance] setPostAT_Tag:[[BFTDataHandler sharedInstance] BUN]];
    NSLog(@"%@", [[BFTDataHandler sharedInstance] mp4Name]);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    if ([_hashtagEditText isFirstResponder] && [touch view] != _hashtagEditText) {
        [_hashtagEditText resignFirstResponder];
    }
    [super touchesBegan:touches withEvent:event];
}

-(void)popVC {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - BFTCameraViewDelegate

-(BOOL)canUploadVideo {
    if ([[BFTPostHandler sharedInstance] postCategory] == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Please select a category" message:@"you didn't select a category for your video." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        return NO;
    }
    
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
    _videoPosted = YES;
    if (_thumbUploaded && _videoPosted) {
        [self everythingFinished];
    }
}

-(void)videoSentToUser {
    NSLog(@"Video Sent To User");
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

#pragma mark - Button Actions

- (IBAction)moveClicked:(id)sender {
    if(![_moveButton isSelected]){
        [[BFTPostHandler sharedInstance] setPostCategory:1];
        [_moveButton setSelected:YES];
        [_studyButton setSelected:NO];
        [_loveButton setSelected:NO];
        [_grubButton setSelected:NO];
        [_categoryLabel setText:@"Move"];
        [_categoryLabel setTextColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    }else{
        [_moveButton setSelected:NO];
        [[BFTPostHandler sharedInstance] setPostCategory:0];
        [_categoryLabel setText:@"Choose Category"];
        [_categoryLabel setTextColor:[UIColor colorWithWhite:0.5 alpha:1]];
    }
}

- (IBAction)grubClicked:(id)sender {
    if(![_grubButton isSelected]){
        [[BFTPostHandler sharedInstance] setPostCategory:2];
        [_grubButton setSelected:YES];
        [_studyButton setSelected:NO];
        [_loveButton setSelected:NO];
        [_moveButton setSelected:NO];
        [_categoryLabel setText:@"Grub"];
        [_categoryLabel setTextColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    }else{
        [_grubButton setSelected:NO];
        [[BFTPostHandler sharedInstance] setPostCategory:0];
        [_categoryLabel setText:@"Choose Category"];
        [_categoryLabel setTextColor:[UIColor colorWithWhite:0.5 alpha:1]];
    }
}

- (IBAction)loveClicked:(id)sender {
    if(![_loveButton isSelected]){
        [[BFTPostHandler sharedInstance] setPostCategory:3];
        [_loveButton setSelected:YES];
        [_studyButton setSelected:NO];
        [_moveButton setSelected:NO];
        [_grubButton setSelected:NO];
        [_categoryLabel setText:@"Love"];
        [_categoryLabel setTextColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    }else{
        [_loveButton setSelected:NO];
        [[BFTPostHandler sharedInstance] setPostCategory:0];
          [_categoryLabel setText:@"Choose Category"];
        [_categoryLabel setTextColor:[UIColor colorWithWhite:0.5 alpha:1]];
    }
}

- (IBAction)studyClicked:(id)sender {
    if(![_studyButton isSelected]){
        [[BFTPostHandler sharedInstance] setPostCategory:4];
        [_studyButton setSelected:YES];
        [_moveButton setSelected:NO];
        [_loveButton setSelected:NO];
        [_grubButton setSelected:NO];
        [_categoryLabel setText:@"Study"];
        [_categoryLabel setTextColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
//        _categoryLabel.center = CGPointMake(0, 13);
    }else{
        [_studyButton setSelected:NO];
        [[BFTPostHandler sharedInstance] setPostCategory:0];
        [_categoryLabel setText:@"Choose Category"];
        [_categoryLabel setTextColor:[UIColor colorWithWhite:0.5 alpha:1]];
//        _categoryLabel.center = CGPointMake(55,12);
    }
}

- (IBAction)updateHashtag:(id)sender {
    [[BFTPostHandler sharedInstance] setPostHash_tag:[_hashtagEditText text]];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
