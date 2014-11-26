//
//  BFTMainViewController.m
//  Bafit
//
//  Created by Keeano Martin on 7/23/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTMainViewController.h"
#import "BFTDataHandler.h"
#import "BFTAppDelegate.h"
#import "BFTVideoResponseViewController.h"
#import "BFTDataHandler.h"
#import "BFTPostHandler.h"
#import "BFTDatabaseRequest.h"
#import "BFTVideoPost.h"
#import "BFTMessageThreads.h"
#import "BFTMainPostViewController.h"
#import "BFTVideoPlaybackController.h"
#import "BFTCarouselView.h"
#import "BFTConstants.h"
#import "NSDate+relativeTimeStamp.h"

@interface BFTMainViewController ()

@end

@implementation BFTMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //init temp image cahce with max size of 100 mb
    _tempImageCache = [[NSCache alloc] init];
    [_tempImageCache setTotalCostLimit:100*1024*1024];
    
    //start PostHandler
    [[BFTPostHandler sharedInstance] setPostUID:[[BFTDataHandler sharedInstance]UID]];
    
    //set background color
    [self.view setBackgroundColor:kOrangeColor];
    [_customNavView setBackgroundColor:kOrangeColor];
    
    //set catagory
    _items = [NSMutableArray array];
    _catagory = 0;
    //[self loadURLsFromCatagory:_catagory replacingRemovedVideo:NO];
    
    //configure carousel
    _carousel.delegate = self;
    _carousel.dataSource = self;
    _carousel.type = iCarouselTypeLinear;
    
    //TODO: Cleanup
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    [self.titleLabel setFont:[UIFont fontWithName:kFuturaBoldFont size:20]];
    
    //add report user button
    UIButton *reportButton = [[UIButton alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height-40, 80, 40)];
    [reportButton setBackgroundImage:[UIImage imageNamed:@"report_btn.png"] forState:UIControlStateNormal];
    [reportButton addTarget:self action:@selector(showReportUserConfirmation) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:reportButton];
    
    //add feedback button
    UIButton *feedbackButton = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width-80, [UIScreen mainScreen].bounds.size.height-40, 80, 40)];
    [feedbackButton setBackgroundImage:[UIImage imageNamed:@"feedback_btn.png"] forState:UIControlStateNormal];
    [feedbackButton addTarget:self action:@selector(submitFeedback:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:feedbackButton];
    
    _videoPlaybackControllers = [[NSMutableDictionary alloc] init];
    //Check Messages from Queue
    [self checkMessages];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:(BOOL)animated];
    
    _videoPlayback = [[UIView alloc] initWithFrame:CGRectMake(60, 210,200, 220)];
    [_videoPlayback setHidden:YES];
    [self.view addSubview:_videoPlayback];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    
    //set us as the message delegate so we can change the backbutton image if we need to
    [((BFTAppDelegate*)[[UIApplication sharedApplication] delegate]) setMessageDelegate:self];
    
    [self refreshCarousel];
    
    if ([[BFTMessageThreads sharedInstance] unreadMessages]) {
        [self.backButton setImage:[UIImage imageNamed:@"baf_left_active.png"] forState:UIControlStateNormal];
        self.notificationImageAssigned = YES;
    }
    else {
        [self.backButton setImage:[UIImage imageNamed:@"baf_left_inactive.png"] forState:UIControlStateNormal];
        self.notificationImageAssigned = NO;
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [((BFTAppDelegate*)[[UIApplication sharedApplication] delegate]) setMessageDelegate:self];
    [self stopPlayingLastVideo];
}

-(void)respondToUser {
    [self setSwipeUp:YES];
    [self performSegueWithIdentifier:@"topostview" sender:self];
}

-(void)notToday {
    NSInteger index = [_carousel currentItemIndex];
    if (index < [_videoPosts count]) {
        [self removeVideoPostAtIndex:index];
    }
}

- (IBAction)handleSwipeUp:(UIGestureRecognizer *)recognizer __deprecated {
    [self setSwipeUp:YES];
    [self performSegueWithIdentifier:@"topostview" sender:self];
}

- (IBAction)SwipeDown:(UIGestureRecognizer *)recognizer __deprecated {
   //NSInteger index = [_carousel indexOfItemView:[_carousel itemViewAtPoint:[recognizer locationInView:self.view]]];
    NSInteger index = [_carousel currentItemIndex];
    if (index < [_videoPosts count]) {
        [self removeVideoPostAtIndex:index];
    }
}

-(void)removeVideoPostAtIndex:(NSInteger)index {
    BFTVideoPost *post = [_videoPosts objectAtIndex:index];
    [_videoPosts removeObjectAtIndex:index];
    [self.carousel removeItemAtIndex:index animated:YES];
    [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"notToday.php?UIDr=%@&UIDp=%@&MC=%zd", [BFTDataHandler sharedInstance].UID, post.UID, post.MC] trueOrFalseBlock:^(BOOL succes, NSError *error) {
        if (!error) {
            if (succes) {
                [self loadURLsFromCatagory:_catagory replacingRemovedVideo:YES];
            }
        }
        else {
            //handle connection error
        }
    }] startConnection];
    NSLog(@"Removed item from carousel at index: %zd", index);
}

/*
 Loads url's from a given segment. If videoRemoved is set to true, that means that we have swiped down on a video, and we only want to retrieve the new video from the segment
 */
-(void)loadURLsFromCatagory:(NSInteger)catagory replacingRemovedVideo:(BOOL)videoRemoved {
    BFTDataHandler *userData = [BFTDataHandler sharedInstance];
    [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"http://bafit.mobi/cScripts/v1/requestUserList.php?UIDr=%@&GPSlat=%f&GPSlon=%f&Filter=%d&FilterValue=%d", [userData UID], [userData Latitude], [userData Longitude], 1, _catagory] completionBlock:^(NSMutableData *data, NSError *error) {
        if (!error) {
            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            
            if (!error) {
                //create the lists if not already created
                if (!_videoPosts)
                    _videoPosts = [[NSMutableOrderedSet alloc] initWithCapacity:[jsonArray count]];
                
                //If a video is removed, we need to get the post that we don't currently have form the segment we just reloaded. Note that this could be any of them due to videos being added, deleted, location changes, etc.
                if (videoRemoved) {
                    NSMutableOrderedSet *tempPosts = [[NSMutableOrderedSet alloc] initWithCapacity:[jsonArray count]];
                    for (NSDictionary *dict in jsonArray) {
                        [tempPosts addObject:[[BFTVideoPost alloc] initWithDictionary:dict]];
                    }
                    [tempPosts minusOrderedSet:_videoPosts];
                    NSLog(@"New Set - Old Set: \n%@", tempPosts);
                    for (BFTVideoPost *post in tempPosts) {
                        NSInteger previousCount = [_videoPosts count];
                        [_videoPosts addObject:post];
                        if (previousCount == ([_videoPosts count] - 1)) {
                            [self.carousel insertItemAtIndex:[_videoPosts count] animated:YES];
                        }
                        else {
                            NSLog(@"Duplicate Found | Not Added: %@", post);
                        }
                    }
                }
                else {
                    for (NSDictionary *dict in jsonArray) {
                        NSInteger previousCount = [_videoPosts count];
                        BFTVideoPost *post = [[BFTVideoPost alloc] initWithDictionary:dict];
                        [_videoPosts addObject:post];
                        if (previousCount == ([_videoPosts count] - 1)) {
                            [self.carousel insertItemAtIndex:[_videoPosts count] animated:YES];
                        }
                        else {
                            NSLog(@"Duplicate Found | Not Added: %@", post);
                        }
                    }
                }
            }
            else {
                [[[UIAlertView alloc] initWithTitle:@"Unable To Load Video Feed" message:error.localizedDescription delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"Unable To Load Video Feed" message:error.localizedDescription delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }] startConnection];
}

-(void)updateCategory:(NSInteger)category {
    BFTDataHandler *userData = [BFTDataHandler sharedInstance];
    [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"http://bafit.mobi/cScripts/v1/requestUserList.php?UIDr=%@&GPSlat=%f&GPSlon=%f&Filter=%d&FilterValue=%d", [userData UID], [userData Latitude], [userData Longitude], 1, _catagory] completionBlock:^(NSMutableData *data, NSError *error) {
        if (!error) {
            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
            _videoPosts = [[NSMutableOrderedSet alloc] initWithCapacity:[jsonArray count]];
            [self.carousel reloadData];
            
            for (NSDictionary *dict in jsonArray) {
                [_videoPosts addObject:[[BFTVideoPost alloc] initWithDictionary:dict]];
                //[self.carousel insertItemAtIndex:[_videoPosts count] animated:YES];
            }
            [self.carousel reloadData];
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"Unable To Load Video Feed" message:error.localizedDescription delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }] startConnection];
}

-(void)refreshCarousel {
    [self updateCategory:_catagory];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)checkMessages {
    if ([[BFTDataHandler sharedInstance]numberMessages].count <= 0) {
        [_MessageCountLabel setTitle:@"" forState:UIControlStateNormal];
        [_MessageCountLabel setEnabled:NO];
        [_MessageCountLabel setHidden:YES];
    }else{
        [_MessageCountLabel setEnabled:NO];
        [_MessageCountLabel setHidden:NO];
        [_MessageCountLabel setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)[[BFTDataHandler sharedInstance] numberMessages].count] forState:UIControlStateNormal];
    }
}

#pragma mark iCarousel methods

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    //return the total number of items in the carousel
    return [_videoPosts count];
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view {
    BFTCarouselView *mainView;
    
    if (!view) {
        mainView = [[BFTCarouselView alloc] init];
    }
    else {
        mainView = (BFTCarouselView*)view;
    }
    
    //Video Player View
    NSURL *thumbURL = [[NSURL alloc] initWithString:[[_videoPosts objectAtIndex:index] thumbURL]];
    NSURL *videoURL = [[NSURL alloc] initWithString:[[_videoPosts objectAtIndex:index] videoURL]];
    
    BFTVideoPlaybackController* videoPlayer = [[BFTVideoPlaybackController alloc] initWithVideoURL:videoURL andThumbURL:thumbURL frame:CGRectMake(0, 72, 216, 216)];
    [_videoPlaybackControllers setObject:videoPlayer forKey:[NSNumber numberWithUnsignedInteger:index]];
    
    UITapGestureRecognizer *tapToPlay = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(videoSelected:)];
    
    [videoPlayer.view addGestureRecognizer:tapToPlay];
    _videoView = videoPlayer.view;
    mainView.videoPlaybackView = videoPlayer.view;
    
    //Assign Item to Labels
    BFTVideoPost *post = [self.videoPosts objectAtIndex:index];
    mainView.usernameLabel.text = [NSString stringWithFormat:@"@%@", [post BUN]];
    mainView.postTimeLabel.text = [[post timeStamp] relativeTimeStamp];
    mainView.distanceLabel.text = [NSString stringWithFormat:@"%.1f miles away", [post distance]];
    mainView.hashTagLabel.text = [NSString stringWithFormat:@"%@", [post hashTag]];
    [mainView.responseButton addTarget:self action:@selector(respondToUser) forControlEvents:UIControlEventTouchUpInside];
    [mainView.notTodayButton addTarget:self action:@selector(notToday) forControlEvents:UIControlEventTouchUpInside];
    
    return mainView;
}

-(void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index {
    
}

-(void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel {
    if (!(self.carousel.currentItemIndex == self.currentVideoPlaybackIndex)) {
        [self pauseLastVideo];
    }
}

- (NSUInteger)numberOfVisibleItemsInCarousel:(iCarousel *)carousel
{
    return 1;
}

- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    switch (option)
    {
        case iCarouselOptionFadeMin:
            return -0.2;
        case iCarouselOptionFadeMax:
            return 0.2;
        case iCarouselOptionFadeRange:
            return 2.0;
        default:
            return value;
    }
}

-(IBAction)videoSelected:(id)sender {
    NSInteger index = [_carousel currentItemIndex];
    BFTVideoPlaybackController* videoPlayer = [self.videoPlaybackControllers objectForKey:[NSNumber numberWithUnsignedInteger:index]];
    if (self.currentVideoPlaybackIndex != index) {
        [self pauseLastVideo];
    }
    self.currentVideoPlaybackIndex = index;
    [videoPlayer togglePlayback];
}

-(void)stopPlayingLastVideo {
    BFTVideoPlaybackController* lastVideoPlayer = [self.videoPlaybackControllers objectForKey:[NSNumber numberWithUnsignedInteger:self.currentVideoPlaybackIndex]];
    [lastVideoPlayer stop];
}

-(void)pauseLastVideo {
    BFTVideoPlaybackController* lastVideoPlayer = [self.videoPlaybackControllers objectForKey:[NSNumber numberWithUnsignedInteger:self.currentVideoPlaybackIndex]];
    [lastVideoPlayer pause];
}

-(IBAction)didFinishPlaying:(id)sender
{
    NSLog(@"Did Finish Playing");
    [_videoPlayback setHidden:YES];
}

/* Segue Preperation */
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([segue.identifier isEqualToString:@"topostview"])
    {
        if (!_swipeUp) {
            //Regularly handle post message
        } else{
            //swipe up to post
            [self setSwipeUp:NO];
            BFTVideoResponseViewController *postView = segue.destinationViewController;
            if (_carousel.currentItemIndex < [_videoPosts count]) {
                postView.postResponse = [_videoPosts objectAtIndex:_carousel.currentItemIndex];
            }
            else {
                NSLog(@"Could not respond to video");
            }
        }
    }
    
    if ([segue.identifier isEqualToString:@"newpostview"]) {
        BFTMainPostViewController *meerPost = segue.destinationViewController;
        meerPost.postFromView = YES;
    }
    
}

#pragma mark - Action Sheet

-(void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self blockUser];
    }
    return;
}

-(void)showReportUserConfirmation {
    UIActionSheet *actSheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure you want to report this user? You will no longer recieve any updates from them." delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Report User" otherButtonTitles:nil];
    [actSheet showInView:self.view];
}

#pragma mark - Buttons

-(IBAction)blockUser {
    NSInteger index = [_carousel currentItemIndex];
    
    BFTVideoPost *post = [_videoPosts objectAtIndex:index];
    [_videoPosts removeObjectAtIndex:index];
    [self.carousel removeItemAtIndex:index animated:YES];
    
    [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"blockUser.php?UIDr=%@&UIDp=%@&GPSlat=%.4f&GPSlon=%.4f", [[BFTDataHandler sharedInstance] UID], post.UID, [[BFTDataHandler sharedInstance] Latitude], [[BFTDataHandler sharedInstance] Longitude]] trueOrFalseBlock:^(BOOL success, NSError *error) {
        if (!error) {
            [self loadURLsFromCatagory:_catagory replacingRemovedVideo:YES];
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"Could not block user" message:error.localizedDescription delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        }
    }] startConnection];
}

-(IBAction)submitFeedback:(UIButton *)sender {
    NSLog(@"Submit Feedback");
    [self performSegueWithIdentifier:@"tofeedback" sender:self];
}

-(IBAction)postThread:(id)sender {
    /*NOTE: I was getting an error here (ARC Semantic issue, multiple instances of method tag". I think this is because of the logging framework, but it doesnt seem like this method is being used, so i commented it out.
    NSLog(@"Index Button Number: %ld", (long)[sender tag]);
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:[[_videoPosts objectAtIndex:[sender tag]] videoURL]] options:nil];
    //AV Asset Player
    AVPlayerItem * playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
    _player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    playerLayer.frame = CGRectMake(_videoView.frame.origin.x, _videoView.frame.origin.y - 60, _videoView.frame.size.width, _videoView.frame.size.height);
    //        [playerLayer setFrame:_videoView.frame];
    [_videoView.layer addSublayer:playerLayer];
    [_player seekToTime:kCMTimeZero];
    [_player play];
    */
}

- (IBAction)backToThread:(id)sender {
    [self performSegueWithIdentifier:@"backthread" sender:self];
}

- (IBAction)forthToPost:(id)sender {
}

#pragma mark Message Delegate

-(void)recievedMessage {
    //checking a bool is faster than reassigning the image everytime we get a message
    if (!self.notificationImageAssigned) {
        [self.backButton setImage:[UIImage imageNamed:@"baf_left_active.png"] forState:UIControlStateNormal];
        self.notificationImageAssigned = YES;
    }
}

#pragma mark Catagory Selection

- (IBAction)moveCatTouched:(id)sender {
    if (![_moveCatButton isSelected]) {
        _catagory = 1;
        [self updateCategory:_catagory];
        
        [_moveCatButton setSelected:YES];
        //otherButtons are not active
        [_studyCatButton setSelected:NO];
        [_loveCatButton setSelected:NO];
        [_grubCatButton setSelected:NO];
    }
    else {
        [_moveCatButton setSelected:NO];
        _catagory = 0;
        [self updateCategory:_catagory];
    }
}

- (IBAction)studyCatTouched:(id)sender {
    if (![_studyCatButton isSelected]) {
        _catagory = 2;
        [self updateCategory:_catagory];
        
        [_studyCatButton setSelected:YES];
        //otherButtons are not active
        [_moveCatButton setSelected:NO];
        [_loveCatButton setSelected:NO];
        [_grubCatButton setSelected:NO];
    }
    else {
        [_studyCatButton setSelected:NO];
        _catagory = 0;
        [self updateCategory:_catagory];
    }
}

- (IBAction)loveCatTouched:(id)sender {
    if (![_loveCatButton isSelected]) {
        _catagory = 3;
        [self updateCategory:_catagory];
        
        [_loveCatButton setSelected:YES];
        //otherButtons are not active
        [_studyCatButton setSelected:NO];
        [_moveCatButton setSelected:NO];
        [_grubCatButton setSelected:NO];
    }
    else {
        [_loveCatButton setSelected:NO];
        _catagory = 0;
        [self updateCategory:_catagory];
    }
}

- (IBAction)grubCatTouched:(id)sender {
    if (![_grubCatButton isSelected]) {
        _catagory = 4;
        [self updateCategory:_catagory];
        
        [_grubCatButton setSelected:YES];
        //otherButtons are not active
        [_studyCatButton setSelected:NO];
        [_loveCatButton setSelected:NO];
        [_moveCatButton setSelected:NO];
    }
    else {
        [_grubCatButton setSelected:NO];
        _catagory = 0;
        [self updateCategory:_catagory];
    }
}


@end
