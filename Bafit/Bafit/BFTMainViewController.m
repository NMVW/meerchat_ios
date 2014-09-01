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

@interface BFTMainViewController ()

@end

@implementation BFTMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    //set background color
    [self.view setBackgroundColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    [_customNavView setBackgroundColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    //set catagory
    _catagory = 0;
    
    //configure carousel
    _carousel.delegate = self;
    _carousel.dataSource = self;
    _carousel.type = iCarouselTypeLinear;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    //add report user button
    UIButton *reportButton = [[UIButton alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height-39, 93, 39)];
    [reportButton setBackgroundImage:[UIImage imageNamed:@"reportUserButton.png"] forState:UIControlStateNormal];
    [reportButton setBackgroundImage:[UIImage imageNamed:@"reportUserButtonHighlighted.png"] forState:UIControlStateHighlighted];
    [reportButton addTarget:self action:@selector(blockUser:) forControlEvents:UIControlEventTouchUpInside];
    [reportButton.titleLabel setFont:[UIFont systemFontOfSize:13]];
    [reportButton setTitle:@"report user" forState:UIControlStateNormal];
    [self.view addSubview:reportButton];
    
    //add feedback button
    UIButton *feedbackButton = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width-93, [UIScreen mainScreen].bounds.size.height-39, 93, 39)];
    [feedbackButton setBackgroundImage:[UIImage imageNamed:@"feedbackButton.png"] forState:UIControlStateNormal];
    [feedbackButton setBackgroundImage:[UIImage imageNamed:@"feedbackButtonHighlighted.png"] forState:UIControlStateHighlighted];
    [feedbackButton addTarget:self action:@selector(submitFeedback:) forControlEvents:UIControlEventTouchUpInside];
    [feedbackButton.titleLabel setFont:[UIFont systemFontOfSize:13]];
    [feedbackButton setTitle:@"Feedback" forState:UIControlStateNormal];
    [self.view addSubview:feedbackButton];
    
    //this is just for testing, if we want to skip right to the main view we will need a uid
    if (![[BFTDataHandler sharedInstance] UID]) {
        [[BFTDataHandler sharedInstance] setUID:[[NSUUID UUID] UUIDString]];
    }
    
    
    [self loadURLsFromCatagory:_catagory replacingRemovedVideo:NO];
    
    _items = [NSMutableArray array];
    
    //Check Messages from Queue
    [self checkMessages];
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


-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:(BOOL)animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    //Create and handle Video Player for Videos in thread
    _videoPlayback = [[UIView alloc] initWithFrame:CGRectMake(60, 210,200, 220)];
//    [_videoPlayback setBackgroundColor:[UIColor colorWithWhite:-100 alpha:1.0]];
    [_videoPlayback setHidden:YES];
    [self.view addSubview:_videoPlayback];
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
    UILabel *pointLabel = nil;
    UIButton *reportUser = nil;
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
    topTrapazoid.image = [UIImage imageNamed:@"upper-trap@2x.png"];
    topTrapazoid.tag = 4;
    [mainView addSubview:topTrapazoid];
    UILabel *responseLabel = [[UILabel alloc] initWithFrame:topTrapazoid.bounds];
    responseLabel.center = CGPointMake(180, 15);
    responseLabel.textColor = [UIColor colorWithRed:243/255.0f green:172/255.0f blue:40/255.0f alpha:1.0];
    responseLabel.font = [responseLabel.font fontWithSize:10];
    responseLabel.tag = 8;
    responseLabel.text = @"respond";
    [mainView addSubview:responseLabel];
        
    UIImageView *dividerTop = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 167, 1)];
    dividerTop.image = [UIImage imageNamed:@"dividerbar.png"];
    dividerTop.center = CGPointMake(100, 30);
    [mainView addSubview:dividerTop];
    
    //Video Player View
    UIImageView *videoThumb = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, mainViewWidth, 220)];
    videoThumb.backgroundColor = [UIColor colorWithRed:123/255.0 green:123/255.0 blue:123/255.0 alpha:1.0];
    videoThumb.center = CGPointMake(100, 170);
    [videoThumb setContentMode:UIViewContentModeScaleAspectFit];
    //[_videoView setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[[_videoPosts objectAtIndex:index] thumbURL]]]]];
    [[[BFTDatabaseRequest alloc] initWithFileURL:[[_videoPosts objectAtIndex:index] thumbURL] completionBlock:^(NSMutableData *data, NSError *error) {
        if (!error) {
            [videoThumb setImage:[UIImage imageWithData:data]];
        }
        else {
            //handle image download error
        }
    }] startImageDownload];
    
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
    UIImageView *bottomTrapazoid = [[UIImageView alloc] initWithFrame:CGRectMake(0, 280, mainViewWidth, 90)];
    bottomTrapazoid.image = [UIImage imageNamed:@"lower-trap@2x.png"];
    bottomTrapazoid.tag = 6;
    bottomTrapazoid.contentMode = UIViewContentModeScaleToFill;
    [view addSubview:bottomTrapazoid];
    UIImageView *dividerbtm1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 169, 1)];
    dividerbtm1.image = [UIImage imageNamed:@"dividerbar.png"];
    dividerbtm1.center = CGPointMake(100,310);
    [mainView addSubview:dividerbtm1];
    UIImageView *dividerbtm2 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 126, 1)];
    dividerbtm2.image = [UIImage imageNamed:@"dividerbar.png"];
    dividerbtm2.center = CGPointMake(100,346);
    [mainView addSubview:dividerbtm2];
    //Labels
    UILabel *notTodayLabel = [[UILabel alloc] initWithFrame:bottomTrapazoid.bounds];
    notTodayLabel.center = CGPointMake(175, 358);
    notTodayLabel.textColor = [UIColor colorWithRed:243/255.0f green:172/255.0f blue:40/255.0f alpha:1.0];
    notTodayLabel.font = [notTodayLabel.font fontWithSize:10];
    notTodayLabel.tag = 11;
    notTodayLabel.text = @"not today";
    [mainView addSubview:notTodayLabel];
        
    pointLabel = [[UILabel alloc] initWithFrame:bottomTrapazoid.bounds];
    pointLabel.center = CGPointMake(235, 293);
    pointLabel.textColor = [UIColor colorWithWhite:-90 alpha:1.0];
    pointLabel.font = [pointLabel.font fontWithSize:9];
    pointLabel.tag = 12;
    [mainView addSubview:pointLabel];
        
    postTimeLabel = [[UILabel alloc] initWithFrame:bottomTrapazoid.bounds];
    postTimeLabel.center = CGPointMake(120, 294);
    postTimeLabel.textColor = [UIColor colorWithWhite:-100 alpha:1.0];
    postTimeLabel.font = [postTimeLabel.font fontWithSize:9];
    postTimeLabel.tag = 14;
    [mainView addSubview:postTimeLabel];
        
    distanceLabel = [[UILabel alloc] initWithFrame:bottomTrapazoid.bounds];
    distanceLabel.center = CGPointMake(130, 325);
    distanceLabel.textColor = [UIColor colorWithWhite:-100 alpha:1.0];
    distanceLabel.font = [distanceLabel.font fontWithSize:9];
    distanceLabel.tag = 15;
    [mainView addSubview:distanceLabel];
        
        
    reportUser = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60,10)];
    reportUser.center = CGPointMake(140, 325);
    reportUser.titleLabel.font =[reportUser.titleLabel.font fontWithSize:9];
    [reportUser setTitle:@"report user" forState:UIControlStateNormal];
    [reportUser setTitleColor:[UIColor colorWithWhite:-100 alpha:1.0] forState:UIControlStateNormal];
    [mainView addSubview:reportUser];
    
    
    //Assign Item to Labels
    _usernameLabel.text = handler.Username[index%10];
    pointLabel.text = @"32 points";
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
    if (_carousel.currentItemIndex >= 10 - 3) {
//        _segment++;
        [self loadURLsFromCatagory:_catagory replacingRemovedVideo:NO];
    }
}

- (NSUInteger)numberOfVisibleItemsInCarousel:(iCarousel *)carousel
{
    return 3;
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
    
}

- (IBAction)backToThread:(id)sender {
    [self performSegueWithIdentifier:@"backthread" sender:self];
}

- (IBAction)forthToPost:(id)sender {
}

#pragma mark Catagory Selection

- (IBAction)moveCatTouched:(id)sender {
    switch ([_moveCatButton isSelected]) {
        case true:
            [_moveCatButton setBackgroundImage:[UIImage imageNamed:@"move-btn-active.png"] forState:UIControlStateNormal];
            //otherButtons are not active
            [_studyCatButton setBackgroundImage:[UIImage imageNamed:@"study-btn-inactive.png"] forState:UIControlStateNormal];
            [_loveCatButton setBackgroundImage:[UIImage imageNamed:@"love-btn-inactive.png"] forState:UIControlStateNormal];
            [_grubCatButton setBackgroundImage:[UIImage imageNamed:@"grub-btn-inactive.png"] forState:UIControlStateNormal];
             break;
        default:
            //move button selected
            [_moveCatButton setBackgroundImage:[UIImage imageNamed:@"move-btn-inactive.png"] forState:UIControlStateNormal];
            
            break;
    }
}

- (IBAction)studyCatTouched:(id)sender {
    
    switch ([_studyCatButton isSelected]) {
        case true:
            [_studyCatButton setBackgroundImage:[UIImage imageNamed:@"study-btn-active.png"] forState:UIControlStateNormal];
            //otherButtons are not active
            [_moveCatButton setBackgroundImage:[UIImage imageNamed:@"move-btn-inactive.png"] forState:UIControlStateNormal];
            [_loveCatButton setBackgroundImage:[UIImage imageNamed:@"love-btn-inactive.png"] forState:UIControlStateNormal];
            [_grubCatButton setBackgroundImage:[UIImage imageNamed:@"grub-btn-inactive.png"] forState:UIControlStateNormal];
            break;
        default:
            //move button selected
            [_studyCatButton setBackgroundImage:[UIImage imageNamed:@"study-btn-inactive.png"] forState:UIControlStateNormal];
            
            break;
    }

}

- (IBAction)loveCatTouched:(id)sender {
    switch ([_loveCatButton isSelected]) {
        case true:
            [_loveCatButton setBackgroundImage:[UIImage imageNamed:@"love-btn-active.png"] forState:UIControlStateNormal];
            //otherButtons are not active
            [_studyCatButton setBackgroundImage:[UIImage imageNamed:@"study-btn-inactive.png"] forState:UIControlStateNormal];
            [_moveCatButton setBackgroundImage:[UIImage imageNamed:@"move-btn-inactive.png"] forState:UIControlStateNormal];
            [_grubCatButton setBackgroundImage:[UIImage imageNamed:@"grub-btn-inactive.png"] forState:UIControlStateNormal];
            break;
        default:
            //move button selected
            [_loveCatButton setBackgroundImage:[UIImage imageNamed:@"love-btn-inactive.png"] forState:UIControlStateNormal];
            
            break;
    }

}

- (IBAction)grubCatTouched:(id)sender {
    switch ([_grubCatButton isSelected]) {
        case true:
            [_grubCatButton setBackgroundImage:[UIImage imageNamed:@"grub-btn-active.png"] forState:UIControlStateNormal];
            //otherButtons are not active
            [_studyCatButton setBackgroundImage:[UIImage imageNamed:@"study-btn-inactive.png"] forState:UIControlStateNormal];
            [_loveCatButton setBackgroundImage:[UIImage imageNamed:@"love-btn-inactive.png"] forState:UIControlStateNormal];
            [_moveCatButton setBackgroundImage:[UIImage imageNamed:@"move-btn-inactive.png"] forState:UIControlStateNormal];
            break;
        default:
            //move button selected
            [_grubCatButton setBackgroundImage:[UIImage imageNamed:@"grub-btn-inactive.png"] forState:UIControlStateNormal];
            
            break;
    }
}


@end
