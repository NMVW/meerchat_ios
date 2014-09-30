//
//  BFTMainViewController.m
//  Bafit
//
//  Created by Keeano Martin on 7/23/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTMainViewController.h"
#import "BFTHTTPCLIENT.h"
#import "BFTDataHandler.h"
#import "BFTAppDelegate.h"
#import "BFTPostViewController.h"
#import "BFTDataHandler.h"
#import "BFTDatabaseRequest.h"
#import "BFTVideoPost.h"
#import "BFTMessageThreads.h"
#import "BFTMeerPostViewController.h"

@interface BFTMainViewController ()

@end

@implementation BFTMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //init temp image cahce with max size of 100 mb
    _tempImageCache = [[NSCache alloc] init];
    [_tempImageCache setTotalCostLimit:100*1024*1024];
    
    //init array of temp hash tags
    _tempHashTags = [[NSArray alloc] initWithObjects:@"#hookup",@"#cantina101",@"#tequila", nil];
    
    //set background color
    [self.view setBackgroundColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    [_customNavView setBackgroundColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    
    //set catagory
    _items = [NSMutableArray array];
    _catagory = 0;
    [self loadURLsFromCatagory:_catagory replacingRemovedVideo:NO];
    
    //configure carousel
    _carousel.delegate = self;
    _carousel.dataSource = self;
    _carousel.type = iCarouselTypeLinear;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    //add report user button
    UIButton *reportButton = [[UIButton alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height-40, 80, 40)];
    [reportButton setBackgroundImage:[UIImage imageNamed:@"report_btn.png"] forState:UIControlStateNormal];
    [reportButton addTarget:self action:@selector(blockUser:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:reportButton];
    
    //add feedback button
    UIButton *feedbackButton = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width-80, [UIScreen mainScreen].bounds.size.height-40, 80, 40)];
    [feedbackButton setBackgroundImage:[UIImage imageNamed:@"feedback_btn.png"] forState:UIControlStateNormal];
    [feedbackButton addTarget:self action:@selector(submitFeedback:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:feedbackButton];
    
    //Check Messages from Queue
    [self checkMessages];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:(BOOL)animated];
    //Create and handle Video Player for Videos in thread
    _videoPlayback = [[UIView alloc] initWithFrame:CGRectMake(60, 210,200, 220)];
    //    [_videoPlayback setBackgroundColor:[UIColor colorWithWhite:-100 alpha:1.0]];
    [_videoPlayback setHidden:YES];
    [self.view addSubview:_videoPlayback];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    
    //set us as the message delegate so we can change the backbutton image if we need to
    [((BFTAppDelegate*)[[UIApplication sharedApplication] delegate]) setMessageDelegate:self];
    
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
}

- (IBAction)handleSwipeUp:(UIGestureRecognizer *)recognizer {
    [self setSwipeUp:YES];
    [self performSegueWithIdentifier:@"topostview" sender:self];

}

- (IBAction)SwipeDown:(UIGestureRecognizer *)recognizer {
    NSInteger index = [_carousel indexOfItemView:[_carousel itemViewAtPoint:[recognizer locationInView:self.view]]];
    [self removeVideoPostAtIndex:index];
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
            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
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
                    [_videoPosts addObject:post];
                    [self.carousel insertItemAtIndex:[_videoPosts count] animated:YES];
                }
            }
            else {
                for (NSDictionary *dict in jsonArray) {
                    [_videoPosts addObject:[[BFTVideoPost alloc] initWithDictionary:dict]];
                    [self.carousel insertItemAtIndex:[_videoPosts count] animated:YES];
                }
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

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    _usernameLabel = nil;
    UILabel *postTimeLabel = nil;
    UILabel *distanceLabel = nil;
    BFTDataHandler *handler = [BFTDataHandler sharedInstance];
    
    
    //don't do anything specific to the index within
    //this `if (view == nil) {...}` statement because the view will be
    //recycled and used with other index values later
    UIView *mainView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200.0f, 370.0f)];
    view = mainView;
    CGFloat mainViewWidth = mainView.bounds.size.width;
        
    //Header
    UIImageView *topTrapazoid = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, mainViewWidth, 60)];
    topTrapazoid.image = [UIImage imageNamed:@"trapezoid_menu_top.png"];
    topTrapazoid.tag = 4;
    [mainView addSubview:topTrapazoid];
    
    //hashtags
    UILabel *hashTagLabel = [[UILabel alloc] initWithFrame:topTrapazoid.bounds];
    hashTagLabel.center = CGPointMake(125, 45);
    hashTagLabel.textColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    hashTagLabel.font = [hashTagLabel.font fontWithSize:11];
    hashTagLabel.tag = 13;
    hashTagLabel.text = [NSString stringWithFormat:@"%@ %@ %@", _tempHashTags[0],_tempHashTags[1], _tempHashTags[2]];
    [mainView addSubview:hashTagLabel];
    
    UILabel *responseLabel = [[UILabel alloc] initWithFrame:topTrapazoid.bounds];
    responseLabel.center = CGPointMake(178, 15);
    responseLabel.textColor = [UIColor colorWithRed:243/255.0f green:172/255.0f blue:40/255.0f alpha:1.0];
    responseLabel.font = [responseLabel.font fontWithSize:13];
    responseLabel.tag = 8;
    responseLabel.text = @"respond";
    [mainView addSubview:responseLabel];
        
//    UIImageView *dividerTop = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 167, 1)];
//    dividerTop.image = [UIImage imageNamed:@"dividerbar.png"];
//    dividerTop.center = CGPointMake(100, 30);
//    [mainView addSubview:dividerTop];
    
    //Video Player View
    UIImageView *videoThumb = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, mainViewWidth, 220)];
    videoThumb.backgroundColor = [UIColor colorWithRed:123/255.0 green:123/255.0 blue:123/255.0 alpha:1.0];
    videoThumb.center = CGPointMake(100, 170);
    [videoThumb setContentMode:UIViewContentModeScaleAspectFit];
    
    //try to retrieve the image from the temporary cache first
    [videoThumb setImage:[_tempImageCache objectForKey:[[_videoPosts objectAtIndex:index] thumbURL]]];
    
    if (!videoThumb.image) {
        [[[BFTDatabaseRequest alloc] initWithFileURL:[[_videoPosts objectAtIndex:index] thumbURL] completionBlock:^(NSMutableData *data, NSError *error) {
            if (!error) {
                UIImage *image = [UIImage imageWithData:data];
                
                //put the image in a temporary cache so we dont have to reload each time
                [_tempImageCache setObject:image forKey:[[_videoPosts objectAtIndex:index] thumbURL]];
                [videoThumb setImage:image];
            }
            else {
                //handle image download error
            }
        }] startImageDownload];
    }
    
    //video Thumbs
    _videoView = videoThumb;
    [view addSubview:videoThumb];
        
        
    //Username Display
    _usernameLabel = [[UILabel alloc] initWithFrame:_videoView.bounds];
    _usernameLabel.font = [_usernameLabel.font fontWithSize:15];
    _usernameLabel.textColor = [UIColor colorWithWhite:100 alpha:1.0];
    _usernameLabel.center = CGPointMake(_videoView.center.x + 65, 270);
    _usernameLabel.tag = 10;
    [mainView addSubview:_usernameLabel];
    
        
    //footer
    UIImageView *bottomTrapazoid = [[UIImageView alloc] initWithFrame:CGRectMake(0, 280, mainViewWidth, 60)];
    bottomTrapazoid.image = [UIImage imageNamed:@"trapezoid_menu_bottom_segmented.png"];
    bottomTrapazoid.tag = 6;
    bottomTrapazoid.contentMode = UIViewContentModeScaleToFill;
    [view addSubview:bottomTrapazoid];

    //Labels
    UILabel *notTodayLabel = [[UILabel alloc] initWithFrame:bottomTrapazoid.bounds];
    notTodayLabel.center = CGPointMake(175, 325);
    notTodayLabel.textColor = [UIColor colorWithRed:243/255.0f green:172/255.0f blue:40/255.0f alpha:1.0];
    notTodayLabel.font = [notTodayLabel.font fontWithSize:13];
    notTodayLabel.tag = 11;
    notTodayLabel.text = @"not today";
    [mainView addSubview:notTodayLabel];

    
    postTimeLabel = [[UILabel alloc] initWithFrame:bottomTrapazoid.bounds];
    postTimeLabel.center = CGPointMake(220, 295);
    postTimeLabel.textColor = [UIColor colorWithWhite:-100 alpha:1.0];
    postTimeLabel.font = [postTimeLabel.font fontWithSize:11];
    postTimeLabel.tag = 14;
    [mainView addSubview:postTimeLabel];
        
    distanceLabel = [[UILabel alloc] initWithFrame:bottomTrapazoid.bounds];
    distanceLabel.center = CGPointMake(130, 295);
    distanceLabel.textColor = [UIColor colorWithWhite:-100 alpha:1.0];
    distanceLabel.font = [distanceLabel.font fontWithSize:11];
    distanceLabel.tag = 15;
    [mainView addSubview:distanceLabel];
    
    
    //Assign Item to Labels
    _usernameLabel.text = handler.Username[index%10];
    postTimeLabel.text = @"3 hours ago";
    distanceLabel.text = @"4 miles away";
    
    return view;
}

-(void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index {
    
    NSLog(@"Inside select object at index");
    AVPlayerItem *avPlayeritem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:[[_videoPosts objectAtIndex:carousel.currentItemIndex] videoURL]]];
    AVPlayer *avPlayer = [[AVPlayer alloc] initWithPlayerItem:avPlayeritem];
    AVPlayerLayer *avPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:avPlayer];
    [avPlayerLayer setFrame:_videoView.frame];
    avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [avPlayerLayer setNeedsLayout];
    [carousel.currentItemView.layer addSublayer:avPlayerLayer];
    [carousel.currentItemView bringSubviewToFront:_usernameLabel];
    //Assign to notication to check for end of playback
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:avPlayeritem];
    [avPlayer seekToTime:kCMTimeZero];
    [avPlayer play];
    
}

-(void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel {
    //dont need this code anymore. that was only for loading the next segment (but we only have one segment now)
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
        }else{
            //swipe up to post
            [self setSwipeUp:NO];
            BFTPostViewController *postView = segue.destinationViewController;
            postView.replyURL = [[_videoPosts objectAtIndex:_carousel.currentItemIndex] videoURL];
        }
    }
    
    if ([segue.identifier isEqualToString:@"newpostview"]) {
        BFTMeerPostViewController *meerPost = segue.destinationViewController;
        meerPost.postFromView = YES;
    }
    
}

-(IBAction)blockUser:(UIButton *)sender {
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

-(void)recievedMessage:(NSString *)message fromSender:(NSString *)sender {
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
