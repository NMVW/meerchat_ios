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

#import "AFNetworking.h"

#import "NSDate+DateTools.h"

@interface BFTMainViewController ()

@end

@implementation BFTMainViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    BFTDataHandler *data = [BFTDataHandler sharedInstance];
    if (data.initialLogin)
    {
        //REGISTER FOR PARSE PUSH NOTIFICATIONS MOVED TO AFTER REGISTRATION
        [((BFTAppDelegate*)[[UIApplication sharedApplication] delegate]) registerForNotifications];
        
        [data setInitialLogin:false];
        [data saveData];
    }
    
    self.isRefreshing = NO;
    self.refreshGif.hidden = YES;
    self.refresh.hidden = YES;
    self.refreshingLbl.hidden = YES;
    
    //init temp image cache with max size of 100 mb
    _tempImageCache = [[NSCache alloc] init];
    [_tempImageCache setTotalCostLimit:100*1024*1024];
    
    //start PostHandler
    [[BFTPostHandler sharedInstance] setPostUID:[[BFTDataHandler sharedInstance]UID]];
    
    //set background color
    [self.view setBackgroundColor:kOrangeColor];
    [_customNavView setBackgroundColor:kOrangeColor];
    
    //set category
    _items = [NSMutableArray array];
    _catagory = 0;
    //[self loadURLsFromCatagory:_catagory replacingRemovedVideo:NO];
    
    //configure carousel
    _carousel.delegate = self;
    _carousel.dataSource = self;
    _carousel.type = iCarouselTypeLinear;
    
    _videoPosts = [[NSMutableOrderedSet alloc] init];
    
    //TODO: Cleanup
    //[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
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
    
    //Check Messages from Queue ... what is this doing exactly?
    [self checkMessages];
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
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
    self.refresh.hidden = YES;
    [((BFTAppDelegate*)[[UIApplication sharedApplication] delegate]) setMessageDelegate:self];
    [self stopPlayingLastVideo];
}

-(void)respondToUser {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"firstTimeSwipeUp"]) {
        [self setSwipeUp:YES];
        [self performSegueWithIdentifier:@"topostview" sender:self];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstTimeSwipeUp"];
        
        [[[UIAlertView alloc] initWithTitle:@"Swiping Up" message:@"Tap respond or swipe up to send a private Meerchat." delegate:nil cancelButtonTitle:@"Milo, I'm game." otherButtonTitles:nil] show];
    }
}

-(void)notTodayOwnPost {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Confirm Deletion" message:@"Are you sure you want to delete your post?" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        return;
    }];
    UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self deleteCurrentVideo];
    }];
    
    [controller addAction:cancel];
    [controller addAction:delete];
    
    [self presentViewController:controller animated:YES completion:nil];
}

-(void)notToday {
    
    BFTVideoPost *post = [self.videoPosts objectAtIndex:self.carousel.currentItemIndex];
    
    BFTDataHandler *handler = [BFTDataHandler sharedInstance];
    
    //re-enable carousel b/c it's disabled while user is swiping up or down
    [self enableCarousel];
    
    //if is user's own post disable buttons and gray text
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"firstTimeSwipeDown"]) {
        
        //if it's users own video confirm everytime before deleting
        if ([handler.BUN isEqualToString:[post BUN]])
        {
            UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Confirm Deletion" message:@"Are you sure you want to delete your groovy post?" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                return;
            }];
            UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                [self deleteCurrentVideo];
            }];
            
            [controller addAction:cancel];
            [controller addAction:delete];
            
            [self presentViewController:controller animated:YES completion:nil];
        }
        else
        {
            if ([self isModerator]) {
                
                //[self deleteCurrentVideo];
                
                UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Confirm Deletion" message:@"Since you are a moderator, swiping down deletes the video. are you sure you want to continue?" preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    return;
                }];
                UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                    [self deleteCurrentVideo];
                }];
                
                [controller addAction:cancel];
                [controller addAction:delete];
                
                [self presentViewController:controller animated:YES completion:nil];
                
            }
            else
            {
                [self deleteCurrentVideo];
            }
        }
    }
    else {
        
        UIView* viewToAnimate = [_carousel itemViewAtIndex:_carousel.currentItemIndex];
        
        if ([[viewToAnimate.gestureRecognizers description] length] > 0)
        {
        }
        else
        {
            UIPanGestureRecognizer* pgr = [[UIPanGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(handlePan:)];
            [pgr setDelegate:self];
            [viewToAnimate addGestureRecognizer:pgr];
        }
        
        [[[UIAlertView alloc] initWithTitle:@"Swipe Down" message:@"Swipe down posts that lack grooviness so we can keep the mob happy!" delegate:nil cancelButtonTitle:@"Thanks, Milo." otherButtonTitles:nil] show];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstTimeSwipeDown"];
    }
}

- (IBAction)handleSwipeUp:(UIGestureRecognizer *)recognizer __deprecated {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"firstTimeSwipeUp"]) {
        
        BFTDataHandler *handler = [BFTDataHandler sharedInstance];
        
        BFTVideoPost *post = [_videoPosts objectAtIndex:_carousel.currentItemIndex];
        
        //*** if is user's own post disable swipe up functionality
        if ([handler.BUN isEqualToString:[post BUN]])
        {
            [[[UIAlertView alloc] initWithTitle:@"Notice" message:@"Come on, let's be social and avoid talking to ourselves..." delegate:self cancelButtonTitle:@"Milo, you're right." otherButtonTitles:nil] show];
        }
        else
        {
            [self setSwipeUp:YES];
            //[self performSegueWithIdentifier:@"topostview" sender:self];
        }
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstTimeSwipeUp"];
        
        UIView* viewToAnimate = [_carousel itemViewAtIndex:_carousel.currentItemIndex];
        
        if ([[viewToAnimate.gestureRecognizers description] length] > 0)
        {
        }
        else
        {
            UIPanGestureRecognizer* pgr = [[UIPanGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(handlePan:)];
            [pgr setDelegate:self];
            [viewToAnimate addGestureRecognizer:pgr];
        }
        
        [[[UIAlertView alloc] initWithTitle:@"Swiping Up" message:@"Swiping up on videos allows you to respond to the user and chat with them!" delegate:nil cancelButtonTitle:@"Got It!" otherButtonTitles:nil] show];
    }
}

- (IBAction)SwipeDown:(UIGestureRecognizer *)recognizer __deprecated {
    
    if ([self isModerator]) {
        //return;
    }
    
    BFTDataHandler *handler = [BFTDataHandler sharedInstance];
    
    BFTVideoPost *post = [_videoPosts objectAtIndex:_carousel.currentItemIndex];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"firstTimeSwipeDown"]) {
        
        //if it's users own video confirm everytime before deleting
        if ([handler.BUN isEqualToString:[post BUN]])
        {
            UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Confirm Deletion" message:@"Are you sure you want to delete your post?" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                return;
            }];
            UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                [self deleteCurrentVideo];
            }];
            
            [controller addAction:cancel];
            [controller addAction:delete];
            
            [self presentViewController:controller animated:YES completion:nil];
        }
        else
        {
            if ([self isModerator]) {
                
                //[self deleteCurrentVideo];
                
                UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Confirm Deletion" message:@"Since you are a moderator, swiping down deletes the video. are you sure you want to continue?" preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    return;
                }];
                UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                    [self deleteCurrentVideo];
                }];
                
                [controller addAction:cancel];
                [controller addAction:delete];
                
                [self presentViewController:controller animated:YES completion:nil];
                
            }
            else
            {
                [self deleteCurrentVideo];
            }
        }
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstTimeSwipeDown"];
        [[[UIAlertView alloc] initWithTitle:@"Swiping Down" message:@"Tap not today or swipe down to hide this post forever. You will still see other posts by this user." delegate:nil cancelButtonTitle:@"Got It!" otherButtonTitles:nil] show];
    }
}

-(void)enableCarousel {
    self.carousel.scrollEnabled = YES;
    self.carousel.userInteractionEnabled = YES;
}

-(void)deleteCurrentVideo {
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
    
    //re-enable carousel b/c it's disabled while user is swiping up or down
    [self enableCarousel];
    
    NSLog(@"Removed item from carousel at index: %zd", index);
}

/*
 Loads url's from a given segment. If videoRemoved is set to true, that means that we have swiped down on a video, and we only want to retrieve the new video from the segment
 */
-(void)loadURLsFromCatagory:(NSInteger)catagory replacingRemovedVideo:(BOOL)videoRemoved {
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    // cancel all outstanding requests
    [manager.operationQueue cancelAllOperations];
    
    BFTDataHandler *userData = [BFTDataHandler sharedInstance];
    
    NSString* url = [NSString stringWithFormat:@"http://bafit.mobi/cScripts/v1/requestUserList.php?UIDr=%@&GPSlat=%f&GPSlon=%f&Filter=%d&FilterValue=%d&FBID=%@", [userData UID], [userData Latitude], [userData Longitude], 1, _catagory, [userData FBID]];
    NSLog(@"updateCategory url = %@", url);
    
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         //re-enable carousel b/c it's disabled while user is swiping up or down
         [self enableCarousel];
         
         //NSLog(@"SUCCESS JSON: %@", responseObject);
         NSArray *jsonArray = responseObject;
         
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
         failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         //NSLog(@"Error: %@", error);
         [[[UIAlertView alloc] initWithTitle:@"Unable To Load Video Feed" message:error.localizedDescription delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
     }];
}

-(void)updateCategory:(NSInteger)category {
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    // cancel all outstanding requests
    [manager.operationQueue cancelAllOperations];
    
    if (!self.isRefreshing)
    {
        // show main load indicator and hide carousel while loading - better ux
        [self.loadingGif startAnimating];
        self.carousel.hidden = YES;
        
        //TODO: Remove This?
        // Note from Sam: Not sure; this TODO and code were already existing
        [self.carousel reloadData];
    }
    
    BFTDataHandler *userData = [BFTDataHandler sharedInstance];
    
    NSString* url = [NSString stringWithFormat:@"http://bafit.mobi/cScripts/v1/requestUserList.php?UIDr=%@&GPSlat=%f&GPSlon=%f&Filter=%d&FilterValue=%d&FBID=%@", [userData UID], [userData Latitude], [userData Longitude], 1, _catagory, [userData FBID]];
    NSLog(@"updateCategory url = %@", url);
    
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         //NSLog(@"JSON: %@", responseObject);
         NSArray* jsonArray = responseObject;
         
         _videoPosts = [[NSMutableOrderedSet alloc] initWithCapacity:[jsonArray count]];
         
         for (NSDictionary *dict in jsonArray) {
             [_videoPosts addObject:[[BFTVideoPost alloc] initWithDictionary:dict]];
         }
         
         [self setCarouselBackToNormal];
         
         [self.carousel reloadData];
         
         [self.loadingGif stopAnimating];
         self.carousel.hidden = NO;
     }
         failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         [self setCarouselBackToNormal];
         NSLog(@"Error: %@", error);
     }];
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

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel {
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
    mainView.postTimeLabel.text = [post.timeStamp timeAgoSinceNow];
    mainView.distanceLabel.text = [NSString stringWithFormat:@"%.1f miles away", [post distance]];
    
    //if no # symbol add it to each word
    NSRange whiteSpaceRange = [[post hashTag] rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    if (whiteSpaceRange.location != NSNotFound)
    {
        NSArray *allHashTags = [[post hashTag] componentsSeparatedByString:@" "];
        
        NSMutableString* concatHashTags = [NSMutableString string];
        
        for (NSString* hash in allHashTags)
        {
            if([hash hasPrefix:@"#"])
            {
                [concatHashTags appendString:[NSString stringWithFormat:@"%@ ", hash]];
            }
            else
            {
                if ([hash length] > 0)
                {
                    [concatHashTags appendString:[NSString stringWithFormat:@"#%@ ", hash]];
                }
            }
        }
        
        mainView.hashTagLabel.text = concatHashTags;
    }
    else
    {
        NSMutableString* hashTagStr = [NSMutableString string];
        
        if([[post hashTag] hasPrefix:@"#"])
        {
            [hashTagStr appendString:[NSString stringWithFormat:@"%@ ", [post hashTag]]];
        }
        else
        {
            [hashTagStr appendString:[NSString stringWithFormat:@"#%@ ", [post hashTag]]];
        }
        
        mainView.hashTagLabel.text = hashTagStr;
    }
    
    [mainView.responseButton addTarget:self action:@selector(respondToUser) forControlEvents:UIControlEventTouchUpInside];
    [mainView.notTodayButton addTarget:self action:@selector(notToday) forControlEvents:UIControlEventTouchUpInside];
    
    
    BFTDataHandler *handler = [BFTDataHandler sharedInstance];
    
    //NSLog(@"BFTDataHandler BUN = %@ || BFTVideoPost BUN = %@", handler.BUN, [post BUN]);
    
    [mainView.responseButton setTitleColor:kOrangeColor forState:UIControlStateNormal];
    [mainView.notTodayButton setTitleColor:kOrangeColor forState:UIControlStateNormal];
    mainView.responseButton.userInteractionEnabled = YES;
    mainView.notTodayButton.userInteractionEnabled = YES;
    
    //*** if is user's own post disable buttons and gray text
    if ([handler.BUN isEqualToString:[post BUN]])
    {
        [mainView.responseButton setTitleColor:[UIColor colorWithRed:204/255.0 green:204/255.0 blue:204/255.0 alpha:1] forState:UIControlStateNormal];
        [mainView.notTodayButton setTitleColor:kOrangeColor forState:UIControlStateNormal];
        mainView.responseButton.userInteractionEnabled = NO;
        mainView.notTodayButton.userInteractionEnabled = YES;
    }
    else
    {
        [mainView.responseButton setTitleColor:kOrangeColor forState:UIControlStateNormal];
        [mainView.notTodayButton setTitleColor:kOrangeColor forState:UIControlStateNormal];
        mainView.responseButton.userInteractionEnabled = YES;
        mainView.notTodayButton.userInteractionEnabled = YES;
    }
    
    mainView.facebookFriends.hidden = YES;
    
    NSString* graphString = [NSString stringWithFormat:@"/%@/friends/%@", [[BFTDataHandler sharedInstance] FBID], post.FBID];
    
    [FBRequestConnection startWithGraphPath:graphString parameters:nil HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if ([[result objectForKey:@"data"] count] > 0) {
            mainView.facebookFriends.hidden = NO;
        }
    }];
    
    mainView.meerchatConnection.hidden = ![post hasMeerchatConnection];
    
    if ([[post UID] isEqual:[[BFTDataHandler sharedInstance] UID]]) {
        [mainView.notTodayButton setTitle:@"delete" forState:UIControlStateNormal];
    }
    
    // ADD SWIPE GESTURE RECOGNIZER TO NEW VIEW
    UIView* viewToAnimate = mainView;
    
    if ([[viewToAnimate.gestureRecognizers description] length] > 0)
    {
    }
    else
    {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"firstTimeSwipeUp"])
        {
            UIPanGestureRecognizer* pgr = [[UIPanGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(handlePan:)];
            [pgr setDelegate:self];
            [viewToAnimate addGestureRecognizer:pgr];
        }
    }
    
    return mainView;
}

- (void)carouselDidScroll:(iCarousel *)carousel{
    
    // pull to refresh Hack
    if (_carousel.scrollOffset < -0.5f && _carousel.scrollOffset > -0.6f)
    {
        if (!self.isRefreshing)
        {
            self.carousel.userInteractionEnabled = NO;
            self.carousel.scrollEnabled = NO;
            CGSize offset = CGSizeMake(60.0f, 0);
            self.carousel.contentOffset = offset;
            
            self.isRefreshing = YES;
            
            [self setCarouselOffsetAndRefresh];
        }
        
    }
    else
    {
        //self.refresh.hidden = NO;
    }
}

- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel{
    return 1;
}

-(void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index {

}

-(void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel {
    NSLog(@"carouselCurrentItemIndexDidChange index = %ld", (long)_carousel.currentItemIndex);
    if (!(self.carousel.currentItemIndex == self.currentVideoPlaybackIndex)) {
        [self pauseLastVideo];
    }
    
    // ADD SWIPE GESTURE RECOGNIZER TO NEW VIEW
    UIView* viewToAnimate = [_carousel itemViewAtIndex:_carousel.currentItemIndex];
    
    if ([[viewToAnimate.gestureRecognizers description] length] > 0)
    {
    }
    else
    {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"firstTimeSwipeUp"])
        {
            UIPanGestureRecognizer* pgr = [[UIPanGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(handlePan:)];
            [pgr setDelegate:self];
            [viewToAnimate addGestureRecognizer:pgr];
        }
    }
}

// pull to refresh Hack - Set carousel and controls to normal state
-(void)setCarouselBackToNormal {
    [self enableCarousel];
    CGSize offset = CGSizeMake(0, 0);
    self.carousel.contentOffset = offset;
    
    [self.refreshGif stopAnimating];
    self.refreshingLbl.hidden = YES;
    
    self.refresh.hidden = NO;
    
    self.isRefreshing = NO;
}

// pull to refresh Hack - Need to switch from iCarousel to UICollectionView
-(void)setCarouselOffsetAndRefresh {
    
    if (self.isRefreshing && self.refreshGif.isAnimating)
    {
        [self refreshCarousel];
    }
    
    [self.refreshGif startAnimating];
    self.refreshingLbl.hidden = NO;
    self.refreshGif.hidden = NO;
    
    self.refresh.hidden = YES;
}

// pull to refresh Hack - Need to switch from iCarousel to UICollectionView
- (NSUInteger)numberOfVisibleItemsInCarousel:(iCarousel *)carousel
{
    return 1;
}

// pull to refresh Hack - refresh arrow outside of view
- (UIView *)carousel:(iCarousel *)carousel placeholderViewAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 216, 360)];
    view.backgroundColor = [UIColor clearColor];
    
    if (!self.refresh)
    {
        self.refresh = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pull.png"]];
        self.refresh.frame = CGRectMake(80, 130, 100, 61);
    }
    
    [view addSubview:self.refresh];
    
    if (self.carousel.numberOfItems > 0)
    {
        self.refresh.hidden = NO;
    }
    else
    {
        self.refresh.hidden = YES;
    }
    
    return view;
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

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)panGestureRecognizer {
    CGPoint velocity = [panGestureRecognizer velocityInView:panGestureRecognizer.view];
    return fabs(velocity.y) > fabs(velocity.x);
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

-(void)handlePan:(UIPanGestureRecognizer*)recognizer;
{
    if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        //disable carousel while user is panning (swiping) up or down
        self.carousel.scrollEnabled = NO;
        self.carousel.userInteractionEnabled = NO;
        
        CGPoint center = recognizer.view.center;
        CGPoint translation = [recognizer translationInView:recognizer.view];
        //center = CGPointMake(center.x + translation.x, center.y + translation.y);
        
        
        
        CGPoint velocity = [recognizer velocityInView:self.view];
        CGFloat magnitude = sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y));
        CGFloat slideMult = magnitude / 200;
        NSLog(@"magnitude: %f, slideMult: %f", magnitude, slideMult);
        
        float slideFactor = 18.01 * slideMult; // Increase for more of a slide
        CGPoint finalPoint = CGPointMake(recognizer.view.center.x + (velocity.x * slideFactor),
                                         recognizer.view.center.y + (velocity.y * slideFactor));
        finalPoint.x = MIN(MAX(finalPoint.x, 0), self.view.bounds.size.width);
        finalPoint.y = MIN(MAX(finalPoint.y, 0), self.view.bounds.size.height);
        
        if (recognizer.view.frame.origin.y < -79)
        {
            [self respondToUser];
            
            [UIView animateWithDuration:0.12 delay:0 options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{
                
                recognizer.view.layer.opacity = 0.2;
                recognizer.view.center = CGPointMake(center.x, finalPoint.y+10);
            } completion:nil];
            
            //return;
        }
        else
        {
            center = CGPointMake(center.x,
                                 center.y + translation.y);
            
            recognizer.view.center = center;
            [recognizer setTranslation:CGPointZero inView:recognizer.view];
        }
        
    }
    
    
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        //re-enable carousel b/c it's disabled while user is panning
        [self enableCarousel];
        
        NSLog(@"viewToAnimate FRAME = %@", NSStringFromCGRect(recognizer.view.frame));
        
        
        CGPoint center = recognizer.view.center;
        
        CGPoint velocity = [recognizer velocityInView:self.view];
        CGFloat magnitude = sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y));
        CGFloat slideMult = magnitude / 200;
        //NSLog(@"magnitude: %f, slideMult: %f", magnitude, slideMult);
        
        float slideFactor = 0.1 * slideMult; // Increase for more of a slide
        CGPoint finalPoint = CGPointMake(recognizer.view.center.x + (velocity.x * slideFactor),
                                         recognizer.view.center.y + (velocity.y * slideFactor));
        finalPoint.x = MIN(MAX(finalPoint.x, 0), self.view.bounds.size.width);
        finalPoint.y = MIN(MAX(finalPoint.y, 0), self.view.bounds.size.height);
        
        
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            recognizer.view.frame = CGRectMake(0, 0, 216, 360);
            
        } completion:nil];
        
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
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ReportUserConfirmation"]) {
        UIActionSheet *actSheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure you want to report this Meerkat to? I will personally take care of it - Milo" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Report User" otherButtonTitles:nil];
        actSheet.tag = 0;
        [actSheet showInView:self.view];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ReportUserConfirmation"];
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Notice" message:@"Reporting a peer hides all current and future posts by this user." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        alert.tag = 1;
        [alert show];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // if block user first time action show confirmation after alertView
    if (alertView.tag == 1 )
    {
        UIActionSheet *actSheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure you want to report this user? You will no longer recieve any updates from them." delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Report User" otherButtonTitles:nil];
        actSheet.tag = 0;
        [actSheet showInView:self.view];
    }
}

#pragma mark - Buttons

-(IBAction)blockUser {
    NSInteger index = [_carousel currentItemIndex];
    
    BFTVideoPost *post = [_videoPosts objectAtIndex:index];
    [_videoPosts removeObjectAtIndex:index];
    [self.carousel removeItemAtIndex:index animated:YES];
    
    [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"blockUser.php?UIDr=%@&UIDp=%@&GPSlat=%.4f&GPSlon=%.4f", [[BFTDataHandler sharedInstance] FBID], post.FBID, [[BFTDataHandler sharedInstance] Latitude], [[BFTDataHandler sharedInstance] Longitude]] trueOrFalseBlock:^(BOOL success, NSError *error) {
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

#pragma mark -other/temp

- (BOOL)isModerator {
    static NSArray *listOfFounders;
    if (!listOfFounders) {
        //add the username as all lowercas -- that's what it's compared against.
        listOfFounders = @[@"nv", @"cp", @"jpecoraro", @"jbtt", @"bigcherry", @"nixster"]; //, @"sammykg"
    }
    
    NSString *username = [[[BFTDataHandler sharedInstance] BUN] lowercaseString];
    
    BOOL isModerator;
    
    isModerator = NO;
    
    for (NSString *founder in listOfFounders) {
        if ([username isEqualToString:founder]) {
            isModerator = YES;
        }
    }
    
    
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Confirm Deletion" message:@"Since you are a moderator, swiping down deletes the video. are you sure you want to continue?" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        return;
    }];
    
    UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self deleteCurrentVideo];
    }];
    
    [controller addAction:cancel];
    [controller addAction:delete];
    
    //[self presentViewController:controller animated:YES completion:nil];

    NSLog(@"isModerator = %d", isModerator);
    
    return isModerator;
}

@end
