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
#import "BFTAppDelegate.h"
#import "BFTVideoPlaybackController.h"

@interface BFTMainPostViewController ()

@end

@implementation BFTMainPostViewController {
    BOOL _videoPosted;
    BOOL _thumbUploaded;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.canPost = NO;
    self.postBtnColorOrange = YES;
    
    self.hashtagEditText.delegate = self;
    
    //Set Default Data Handler for Post View
    [[BFTDataHandler sharedInstance] setPostView:YES];
    
    // set to 1 to bypass category requirement
    [[BFTPostHandler sharedInstance] setPostCategory:1];
    [[BFTPostHandler sharedInstance] setPostHash_tag:@"#nohashtag"];

    [self getVideoName];
    
    //set Navigation for View
    [self.navigationBar setBarTintColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    [self.navigationBar setTranslucent:NO];
    self.navItem = [[UINavigationItem alloc] init];
    self.navItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"post_center.png"]];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"milo_backtohome.png"] style:UIBarButtonItemStylePlain target:self action:@selector(popVC)];
    self.navItem.leftBarButtonItem = backButton;
    
    [self.navigationBar setItems:@[self.navItem]];
    
    //setup post view record
    //Setup reply record function
    _embeddedRecordView = [[BFTCameraView alloc] initWithFrame:CGRectMake(0, 0, _recordView.frame.size.width, _recordView.frame.size.width) fromView:@"postView"];
    _embeddedRecordView.maxDuration = 10.0;
    _embeddedRecordView.delegate = self;
    [_recordView addSubview:_embeddedRecordView];
    
    [self.view addSubview:_embeddedRecordView.durationProgressBar];
    [self.view bringSubviewToFront:_embeddedRecordView.durationProgressBar];
    
    [self.view bringSubviewToFront:self.postBtnView];
    [self.view bringSubviewToFront:self.clearBtn];
    self.clearBtn.hidden = YES;
    
    
    // Add listener to show Clear Button after recording stops
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showClearButton)
                                                 name:@"showClearButton"
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    
    
    //fixes hidden elements on iphone 4 (480 screens) - poorly designed for the small screen when I (sam) started... this is a patch
    int height =  [[UIScreen mainScreen] bounds].size.height;
    if(height == 480)
    {
        [self.view bringSubviewToFront:self.postBtnView];
        self.postBtnView.frame = CGRectMake(0, 400, 320, 44);
        self.cardView.frame = CGRectMake(40, 0, 240, 406);
    }
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
    // post notification to clear AVCaptureSession in CaptureManager class
    [[NSNotificationCenter defaultCenter] postNotificationName:@"removeSession" object:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - BFTCameraViewDelegate

-(BOOL)canUploadVideo {
    //if ([[BFTPostHandler sharedInstance] postCategory] == 0) {
    //check the category label text, BFTPostHandler was inconsistent in some scenarios
    // Changed condition to "" instead of "Choose a category" to bypass this method -- may reuse for hashtag conditions
    if ([_categoryLabel.text isEqualToString:@""]) {
        if (NSClassFromString(@"UIAlertController") != nil) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Please select a category" message:@"you didn't select a category for your video." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Please select a category" message:@"you didn't select a category for your video." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        }
        
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
    [SVProgressHUD showWithStatus:@"Saving" maskType:SVProgressHUDMaskTypeGradient];
}

-(void)videoUploadMadeProgress:(CGFloat)progress {
    [SVProgressHUD showProgress:progress status:@"Sharing with the mob..." maskType:SVProgressHUDMaskTypeGradient];
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

//notification BTCameraViewDelegate to change the post buttons color if recording progress is greater than 88%
-(void)changePostBtnColor {
    self.postBtnColorOrange = NO;
    
    if (![_categoryLabel.text isEqualToString:@"Choose a category"])
    {
        [self.postBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
}

//notification from BTCameraViewDelegate to change the post buttons color after 3 secs of recording if canUploadVideo
-(void)recordingIsThreeSeconds {
    NSLog(@"recordingIsThreeSeconds");
    self.canPost = YES;
    self.postBtnColorOrange = YES;
    
    if (![_categoryLabel.text isEqualToString:@"Choose a category"])
    {
        [self.postBtn setTitleColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0] forState:UIControlStateNormal];
    }
}

//method to set the Post button to the right color upon toggling category buttons
-(void)decidePostBtnColor {
    if (self.canPost)
    {
        if (self.postBtnColorOrange)
        {
            [self.postBtn setTitleColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0] forState:UIControlStateNormal];
        }
        else
        {
            [self.postBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
    }
    else
    {
        [self.postBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    }
}

#pragma mark - Button Actions
- (IBAction)postBtnClicked:(id)sender {
    if ([self canUploadVideo])
    {
        if (self.canPost)
        {
            [self.postBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            _embeddedRecordView.durationProgressBar.hidden = YES;
            [_embeddedRecordView postBtnClicked];
        }
        else
        {
            _embeddedRecordView.durationProgressBar.hidden = NO;
            if (NSClassFromString(@"UIAlertController") != nil) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Share more with the mob!" message:@"Posts must more than 3 seconds." preferredStyle:UIAlertControllerStyleAlert];
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
        _embeddedRecordView.durationProgressBar.hidden = NO;
    }
}

//refresh record video view -- delete & re-add b/c AVCaptureSession is wiped out
///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)applicationDidBecomeActive:(NSNotification*) notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"removeSession" object:nil];
    self.canPost = NO;
    self.postBtnColorOrange = YES;
    
    [_embeddedRecordView removeFromSuperview];
    [_embeddedRecordView.durationProgressBar removeFromSuperview];
    _embeddedRecordView = nil;
    
    _embeddedRecordView = [[BFTCameraView alloc] initWithFrame:CGRectMake(0, 0, _recordView.frame.size.width, _recordView.frame.size.width) fromView:@"postView"];
    _embeddedRecordView.maxDuration = 10.0;
    _embeddedRecordView.delegate = self;
    [_recordView addSubview:_embeddedRecordView];
    
    [self.view addSubview:_embeddedRecordView.durationProgressBar];
    [self.view bringSubviewToFront:_embeddedRecordView.durationProgressBar];
    
    [self.view bringSubviewToFront:self.postBtnView];
    [self.view bringSubviewToFront:self.clearBtn];
    self.clearBtn.hidden = YES;
    
    [self.postBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
}

//refresh entire view, delete & re-add record video view
- (IBAction)clearBtnClicked:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"removeSession" object:nil];
    self.canPost = NO;
    self.postBtnColorOrange = YES;
    
    [_embeddedRecordView removeFromSuperview];
    [_embeddedRecordView.durationProgressBar removeFromSuperview];
    _embeddedRecordView = nil;
    
    _embeddedRecordView = [[BFTCameraView alloc] initWithFrame:CGRectMake(0, 0, _recordView.frame.size.width, _recordView.frame.size.width) fromView:@"postView"];
    _embeddedRecordView.maxDuration = 10.0;
    _embeddedRecordView.delegate = self;
    [_recordView addSubview:_embeddedRecordView];
    
    [self.view addSubview:_embeddedRecordView.durationProgressBar];
    [self.view bringSubviewToFront:_embeddedRecordView.durationProgressBar];
    
    [self.view bringSubviewToFront:self.postBtnView];
    [self.view bringSubviewToFront:self.clearBtn];
    self.clearBtn.hidden = YES;
    
    [self.postBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
}

// Detached the categories from the MainPostViewController
- (IBAction)moveClicked:(id)sender {
    if(![_moveButton isSelected]){
        [[BFTPostHandler sharedInstance] setPostCategory:1];
        [_moveButton setSelected:YES];
        [_studyButton setSelected:NO];
        [_loveButton setSelected:NO];
        [_grubButton setSelected:NO];
        [_categoryLabel setText:@"Move"];
        [_categoryLabel setTextColor:[UIColor colorWithWhite:0.5 alpha:1]];
        
        [self decidePostBtnColor];
        
    }else{
        [_moveButton setSelected:NO];
        [[BFTPostHandler sharedInstance] setPostCategory:0];
        [_categoryLabel setText:@"Choose a category"];
        [_categoryLabel setTextColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
        
        //deselected category - no selected categories set post button gray
        [self.postBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    }
}

- (IBAction)studyClicked:(id)sender {
    if(![_studyButton isSelected]){
        [[BFTPostHandler sharedInstance] setPostCategory:2];
        [_studyButton setSelected:YES];
        [_moveButton setSelected:NO];
        [_loveButton setSelected:NO];
        [_grubButton setSelected:NO];
        [_categoryLabel setText:@"Study"];
        [_categoryLabel setTextColor:[UIColor colorWithWhite:0.5 alpha:1]];
        
        [self decidePostBtnColor];
        
        //        _categoryLabel.center = CGPointMake(0, 13);
    }else{
        [_studyButton setSelected:NO];
        [[BFTPostHandler sharedInstance] setPostCategory:0];
        [_categoryLabel setText:@"Choose a category"];
        [_categoryLabel setTextColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
        
        //deselected category - no selected categories set post button gray
        [self.postBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
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
        [_categoryLabel setTextColor:[UIColor colorWithWhite:0.5 alpha:1]];
        
        [self decidePostBtnColor];
        
    }else{
        [_loveButton setSelected:NO];
        [[BFTPostHandler sharedInstance] setPostCategory:0];
        [_categoryLabel setText:@"Choose a category"];
        [_categoryLabel setTextColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
        
        //deselected category - no selected categories set post button gray
        [self.postBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    }
}

- (IBAction)grubClicked:(id)sender {
    if(![_grubButton isSelected]){
        [[BFTPostHandler sharedInstance] setPostCategory:4];
        [_grubButton setSelected:YES];
        [_studyButton setSelected:NO];
        [_loveButton setSelected:NO];
        [_moveButton setSelected:NO];
        [_categoryLabel setText:@"Grub"];
        [_categoryLabel setTextColor:[UIColor colorWithWhite:0.5 alpha:1]];
        
        [self decidePostBtnColor];
        
    }else{
        [_grubButton setSelected:NO];
        [[BFTPostHandler sharedInstance] setPostCategory:0];
        [_categoryLabel setText:@"Choose a category"];
        [_categoryLabel setTextColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
        
        //deselected category - no selected categories set post button gray
        [self.postBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    }
}

- (IBAction)updateHashtag:(id)sender {
    [[BFTPostHandler sharedInstance] setPostHash_tag:[_hashtagEditText text]];
}

#pragma mark - UITextField delegat

//add dismiss keyboard bar button item when entering hashtags
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    NSLog(@"textFieldDidBeginEditing");
    //self.dismiss;
    self.navItem.rightBarButtonItem = self.dismiss;
    [self.navigationBar setItems:@[self.navItem]];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.navItem.rightBarButtonItem = nil;
    [self.navigationBar setItems:@[self.navItem]];
}

- (IBAction)hideKey:(id)sender {
    self.navItem.rightBarButtonItem = nil;
    [self.navigationBar setItems:@[self.navItem]];
    [_hashtagEditText resignFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    // hide and close preview player -- otherwise would continue playing in background on next screen
    [_embeddedRecordView closePreview];
    
    //wipe out AVCaptureSession
    [[NSNotificationCenter defaultCenter] postNotificationName:@"removeSession" object:nil];
    [super viewWillDisappear:animated];
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
