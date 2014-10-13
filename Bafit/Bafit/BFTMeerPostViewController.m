//
//  BFTMeerPostViewController.m
//  Bafit
//
//  Created by Keeano Martin on 8/21/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTMeerPostViewController.h"
#import "BFTDataHandler.h"
#import "BFTPostHandler.h"
#import "BFTDatabaseRequest.h"
#import "CaptureManager.h"

@interface BFTMeerPostViewController ()

@end

@implementation BFTMeerPostViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setPostToMainView];
    //Set Data Handler for Post View
    [[BFTDataHandler sharedInstance] setPostView:YES];
    BOOL test = [[BFTDataHandler sharedInstance] postView];
    NSLog(test ? @"YES" : @"NO");

    [self MP4NameGet];

    
    //set Naivagtion for View
    [self.navigationBar setBarTintColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    [self.navigationBar setTranslucent:NO];
    UINavigationItem *navItem = [[UINavigationItem alloc] init];
    navItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"post_center.png"]];
    UIButton *backButton = [[UIButton alloc] initWithFrame: CGRectMake(0, 0, 30, 30)];
    [backButton setImage:[UIImage imageNamed:@"milo_backtohome.png"]  forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(popVC) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barbtn = [[UIBarButtonItem alloc]initWithCustomView:backButton];
    navItem.leftBarButtonItem = barbtn;
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
    [_recordView addSubview:_embeddedRecordView];
//    _embeddedRecordView = [[KZCameraView alloc] initWithFrame:_recordView.frame withVideoPreviewFrame:CGRectMake(0, 0, 275, 275)];
//    _embeddedRecordView.maxDuration = 10.0;
//    [_recordView addSubview:_embeddedRecordView];
}

-(void)MP4NameGet {
    
    //    __block NSString *mp4Name = nil;
    [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"http://bafit.mobi/cScripts/v1/registerVid.php?UIDr=%@&UIDp=%@", [[BFTDataHandler sharedInstance] UID], [[BFTDataHandler sharedInstance] UID]] completionBlock:^(NSMutableData *data, NSError *error) {
        
        //handle JSON from step one
        if (!error) {
            NSArray *responseJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            for (NSDictionary *dict in responseJSON) {
                NSLog(@"Object value: %@", [dict allKeys]);
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

-(void)popVC {
    [self.navigationController popViewControllerAnimated:YES];
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
    //set Bool for Post from Meerchat
    [self setPostFromView:@"toMainView"];
    
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

-(void)uploadToMain {
    
    BFTDataHandler *userData = [BFTDataHandler sharedInstance];
    [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"http://bafit.mobi/cScripts/v1/registerVid.php?UIDr=%@&UIDp=%@", userData.UID, userData.UID] completionBlock:^(NSMutableData *data, NSError *error) {
        
        //handle JSON from step one
        if (!error) {
            NSArray *responseJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            for (NSDictionary *dict in responseJSON) {
                NSLog(@"Object value: %@", [dict allValues]);
            }
        }else{
            NSLog(@"No Data recived for file type");
        }
    }] startConnection];
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    if ([_hashtagEditText isFirstResponder] && [touch view] != _hashtagEditText) {
        [_hashtagEditText resignFirstResponder];
    }
    [super touchesBegan:touches withEvent:event];
}

- (IBAction)moveClicked:(id)sender {
    if(![_moveButton isSelected]){
        [[BFTPostHandler sharedInstance] setPostCategory:1];
        [_moveButton setSelected:YES];
        [_studyButton setSelected:NO];
        [_loveButton setSelected:NO];
        [_grubButton setSelected:NO];
    }else{
        [_moveButton setSelected:NO];
        [[BFTPostHandler sharedInstance] setPostCategory:0];
    }
}

- (IBAction)grubClicked:(id)sender {
    if(![_grubButton isSelected]){
        [[BFTPostHandler sharedInstance] setPostCategory:2];
        [_grubButton setSelected:YES];
        [_studyButton setSelected:NO];
        [_loveButton setSelected:NO];
        [_moveButton setSelected:NO];
    }else{
        [_grubButton setSelected:NO];
        [[BFTPostHandler sharedInstance] setPostCategory:0];
    }
}

- (IBAction)loveClicked:(id)sender {
    if(![_loveButton isSelected]){
        [[BFTPostHandler sharedInstance] setPostCategory:3];
        [_loveButton setSelected:YES];
        [_studyButton setSelected:NO];
        [_moveButton setSelected:NO];
        [_grubButton setSelected:NO];
    }else{
        [_loveButton setSelected:NO];
        [[BFTPostHandler sharedInstance] setPostCategory:0];
    }
}

- (IBAction)studyClicked:(id)sender {
    if(![_studyButton isSelected]){
        [[BFTPostHandler sharedInstance] setPostCategory:4];
        [_studyButton setSelected:YES];
        [_moveButton setSelected:NO];
        [_loveButton setSelected:NO];
        [_grubButton setSelected:NO];
    }else{
        [_studyButton setSelected:NO];
        [[BFTPostHandler sharedInstance] setPostCategory:0];
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
