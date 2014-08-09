//
//  BFTPostViewController.m
//  Bafit
//
//  Created by Keeano Martin on 8/3/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTPostViewController.h"

@interface BFTPostViewController ()

@end

@implementation BFTPostViewController

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
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    // Do any additional setup after loading the view.
    [self registerForKeyboardNotifications];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:@"http://bafit.mobi/userPosts/v1.mp4"] options:nil];
        //AV Asset Player
        AVPlayerItem * playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
        _player1 = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player1];
    playerLayer.frame = _userVideoView.bounds;
        //        [playerLayer setFrame:_videoView.frame];
        [_userVideoView.layer addSublayer:playerLayer];
        [_player1 seekToTime:kCMTimeZero];
    [_userVideoView addSubview:_playButton];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(playerItemDidReachEnd:)
     name:AVPlayerItemDidPlayToEndTimeNotification
     object:_player1];
    //UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    //imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    //imagePickerController.allowsEditing = YES;
    //imagePickerController.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
    //UIView *videoMessage = [[UIView alloc] initWithFrame:CGRectMake(23, 189, 275, 275)];
    //[videoMessage setBackgroundColor:[UIColor colorWithWhite:-100 alpha:1.0]];
    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:(BOOL)animated];
    [self deregisterFromKeyboardNotifications];
//    //Setup View with Scrollable Content
//     _innerScroll = [[UIScrollView alloc] initWithFrame:self.view.frame];
//    [self.view addSubview:_innerScroll];
//    _recordView = [[UIView alloc] initWithFrame:CGRectMake(20, 240, 275, 275)];
//    [_recordView setBackgroundColor:[UIColor colorWithWhite:-100 alpha:1.0]];
//    [_innerScroll addSubview:_recordView];
//    
//    _recordButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 235, 235)];
//    [_recordButton setTitle:@"Hold to record" forState:UIControlStateNormal];
//    [_recordButton addTarget:self action:@selector(captureVideo:) forControlEvents:UIControlEventTouchUpInside];
//    [_recordView addSubview:_recordButton];
//    
//    //Add video playback View
//    _postVideoPlayBack =[[UIView alloc] initWithFrame:CGRectMake(20, -81, 275, 275)];
//    [_postVideoPlayBack setBackgroundColor:[UIColor colorWithWhite:-100 alpha:1.0]];
//    [_innerScroll addSubview:_postVideoPlayBack];
//    UIButton *playButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60.0f, 60.0f)];
//    [playButton setBackgroundImage:[UIImage imageNamed:@"play-icon-grey.png"] forState:UIControlStateNormal];
//    //[playButton addTarget:self action:@selector(postThread:) forControlEvents:UIControlEventTouchUpInside];
//    playButton.center = CGPointMake(100, 160);
//    [_postVideoPlayBack addSubview:playButton];
//    _innerScroll.contentSize = CGSizeMake(0, 700);
    
    
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    
    NSLog(@"In Finish");
    
    [_player1 seekToTime:kCMTimeZero];
    if ([_playButton isHidden]) {
        [_playButton setHidden:NO];
    }
}


- (IBAction)captureVideo:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        _picker = [[UIImagePickerController alloc] init];
        _picker.allowsEditing = YES;
        _picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        _picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
        [self presentViewController:_picker animated:YES completion:NULL];
    }
}

- (IBAction)playButtonPress:(id)sender {
    
    [_playButton setHidden:YES];
    [_player1 play];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSLog(@"Enter Did Finsih Launching");
    NSString *videoURL = info[UIImagePickerControllerMediaURL];
    [picker dismissViewControllerAnimated:YES completion:NULL];
    _player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:videoURL]];
    [_player.view setFrame:_recordView.bounds];
    [_player prepareToPlay];
    [_player setShouldAutoplay:NO];
    _player.scalingMode = MPMovieScalingModeAspectFit;
    [_recordView addSubview:_player.view];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Keyboard start
- (void)registerForKeyboardNotifications {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
}

- (void)deregisterFromKeyboardNotifications {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidHideNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    
}

- (void)keyboardWasShown:(NSNotification *)notification {
    
    NSDictionary* info = [notification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    CGPoint buttonOrigin = _bottomToolbar.frame.origin;
    CGFloat buttonHeight = _bottomToolbar.frame.size.height;
    CGRect visibleRect = self.view.frame;
    visibleRect.size.height -= keyboardSize.height;
    
    if (!CGRectContainsPoint(visibleRect, buttonOrigin)){
        
        CGPoint scrollPoint = CGPointMake(0.0, buttonOrigin.y - visibleRect.size.height + buttonHeight);
        
        //[_scrollView setContentOffset:scrollPoint animated:YES];
        
    }
    
}

- (void)keyboardWillBeHidden:(NSNotification *)notification {
    
    //[_scrollView setContentOffset:CGPointZero animated:YES];
    
}
//keyboard end


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
