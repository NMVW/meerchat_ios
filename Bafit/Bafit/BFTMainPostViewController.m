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
    [self setPostToMainView];
    //Set Data Handler for Post View
    [[BFTDataHandler sharedInstance] setPostView:YES];

    [self getVideoName];
    
    //set Naivagtion for View
    [self.navigationBar setBarTintColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    [self.navigationBar setTranslucent:NO];
    UINavigationItem *navItem = [[UINavigationItem alloc] init];
    navItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"post_center.png"]];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"milo_backtohome.png"] style:UIBarButtonItemStylePlain target:self action:@selector(popVC)];
    navItem.leftBarButtonItem = backButton;
    [self.navigationBar setItems:@[navItem]];
    
    //Switch handler
    [_locationSwitch addTarget:self action:@selector(stateChangedLocation) forControlEvents:UIControlEventValueChanged];
    [_anonymousSwitch addTarget:self action:@selector(stateChangedUser) forControlEvents:UIControlEventValueChanged];
    
    //set state of lables
    [_userLabel setText:@"post anonymously"];
    [_locationLabel setText:@"hide location"];
    [_userLabel setTextColor:[UIColor colorWithWhite:0.50 alpha:1]];
    [_locationLabel setTextColor:[UIColor colorWithWhite:0.50 alpha:1]];
    
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

-(void)stateChangedLocation {
    if ([_locationSwitch isOn]) {
        //handle on
        _locationLabel.TextColor = [UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0];
        _locationLabel.Text = @"show location";
        //        [self.view addSubview:_locationLabel];
    }else{
        //handle off
        //color back to grey
        [_locationLabel setTextColor:[UIColor colorWithWhite:0.50 alpha:1]];
        _locationLabel.text = @"hide location";
    }
}

-(void)stateChangedUser {
    //Setup switches for privacy
     _data = [BFTDataHandler sharedInstance];
    if ([_anonymousSwitch isOn]) {
        //handle on
        _userLabel.TextColor = [UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0];
        _userLabel.Text = [NSString stringWithFormat:@"Post as %@", [_data BUN]];
        //        [self.view addSubview:_userLabel];
    }else{
        //handle off
        //color back to grey
        [_userLabel setTextColor:[UIColor colorWithWhite:0.50 alpha:1]];
        _userLabel.Text = @"post anonymously";
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setPostToMainView {
    _anonymousSwitch =[[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    _anonymousSwitch.transform = CGAffineTransformMakeScale(0.50f, 0.50f);
    [_anonymousSwitch setOnTintColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    _anonymousSwitch.center = CGPointMake(95, 453);
    [self.view addSubview:_anonymousSwitch];
    
    _locationSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    _locationSwitch.transform = CGAffineTransformMakeScale(0.50f, 0.50f);
    [_locationSwitch setOnTintColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    _locationSwitch.center = CGPointMake(95, 490);
    [self.view addSubview:_locationSwitch];
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
