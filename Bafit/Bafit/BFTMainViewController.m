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

@interface BFTMainViewController ()

@end

@implementation BFTMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _imageObjects = [[NSMutableArray alloc] init];
        //UISwipeGestureRecognizer* _swipeUpGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeUpFrom:)];
        //_swipeUpGestureRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //[self.view addGestureRecognizer:_swipeUpGestureRecognizer];
    _videoURLS = [[NSMutableArray alloc] initWithObjects:@"http://bafit.mobi/userPosts/v1.mp4",
                  @"http://bafit.mobi/userPosts/v2.mp4",
                  @"http://bafit.mobi/userPosts/v3.mp4",
                  @"http://bafit.mobi/userPosts/v4.mp4",
                  @"http://bafit.mobi/userPosts/v5.mp4",
                  @"http://bafit.mobi/userPosts/v6.mp4",
                  @"http://bafit.mobi/userPosts/v7.mp4",
                  @"http://bafit.mobi/userPosts/v8.mp4",
                  @"http://bafit.mobi/userPosts/v9.mp4",
                  @"http://bafit.mobi/userPosts/v10.mp4", nil];
    
//    NSLog(@"%@", [[BFTDataHandler sharedInstance] images]);
    
//    NSError *error = nil;
//    NSString *folderPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Thumbs"];
//    _images = [[NSArray alloc]init];
//    _images = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:&error];
    
    
//    for (int i = 0; i < [_thumbURLS count]; i++) {
//        NSURL *imageURL = [NSURL URLWithString:[_thumbURLS objectAtIndex:i]];
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//            NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                //imageView.image = [UIImage imageWithData:imageData];
//                [_imageObjects addObject:[UIImage imageWithData:imageData]];
//            });
//            NSLog(@"Set image: %lu", (unsigned long)[_imageObjects count]);
//        });
//    }
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];

    
    _items = [NSMutableArray array];
    
    //configure carousel
    _carousel.delegate = self;
    _carousel.dataSource = self;
    _carousel.type = iCarouselTypeLinear;
    
    //Show value for testing
    NSLog(@"Initial Login From Main: %d",[[BFTDataHandler sharedInstance] initialLogin]);
    // Do any additional setup after loading the view.
    NSString *requestUserList = [[NSString stringWithFormat:@"http://www.bafit.mobi/cScripts/requestUserList.php?UIDr=12&GPSLat=%f&GPSLon=%f", [[BFTDataHandler sharedInstance] Latitude],[[BFTDataHandler sharedInstance]Longitude]]stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    self.responseData = [NSMutableData data];
    NSURLRequest *request = [NSURLRequest requestWithURL:
                             [NSURL URLWithString:requestUserList]];
    [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    //getlocation
    NSLog(@"%f",[[BFTDataHandler sharedInstance] Latitude]);
    NSLog(@"%f", [[BFTDataHandler sharedInstance] Longitude]);
    
    //After calls to server
    [self checkMessages];
    
}

- (IBAction)handleSwipeUp:(UIGestureRecognizer *)recognizer {
    [self performSegueWithIdentifier:@"topostview" sender:self];

}

- (IBAction)SwipeDown:(UIGestureRecognizer *)recognizer {
    NSLog(@"Swipe Down Done");
}

-(void)setCarouselVideoObjects:(NSMutableArray *)array {
    for (int i = 0; i < [array count]; i++) {
        MPMoviePlayerController *movieController = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:[array objectAtIndex:i]]];
        if (movieController != nil) {
            //[_videoObjects addObject:movieController];
        }
    }
}

-(void)downloadVideo:(NSString *)videoUrl
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"Download Started");
        NSURL *url = [NSURL URLWithString:videoUrl];
        NSData *urlData = [NSData dataWithContentsOfURL:url];
        
        if (urlData) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *filePath = [NSString stringWithFormat:@"%@%@", documentsDirectory,@"thefile.mp4"];
            [_filePaths addObject:filePath];
            NSLog(@"File Path: %@", filePath);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [urlData writeToFile:filePath atomically:YES];
                NSLog(@"File Saved!");
            });
        }
        
    });
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:(BOOL)animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

-(void)notTodayHandler
{
   // if (_carousel.numberOfItems > 0)
    //{
      //  NSInteger index = _carousel.currentItemIndex;
        //[_carousel removeItemAtIndex:index animated:YES];
        //[_items removeObjectAtIndex:index];
    //}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"didReceiveResponse");
    [self.responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError");
    NSLog(@"Connection failed: %@", [error description]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"connectionDidFinishLoading");
    NSLog(@"Succeeded! Received %lu bytes of data",(unsigned long)[_responseData length]);
    
    // convert to JSON
    NSError *myError = nil;
    NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:_responseData options:NSJSONReadingMutableLeaves error:&myError];
    
    _mutableArray = [[NSMutableArray alloc]init];
    
    for (NSDictionary *sub in jsonArray)
    {
        //[mutableArray addObjectsFromArray:[sub allKeys]];
        [_mutableArray addObject:[sub objectForKey:@"vidURI"]];
    }
    
    //for (id object in mutableArray) {
        //[self downloadVideo:object];
    //}
    
    //[self setDataForPostView:[NSURL URLWithString:[_mutableArray objectAtIndex:0]]];
    
    NSLog(@"Array is: %@", _mutableArray);
    
    // show all values
    for (int i = 0; i < 10; i++) {
        NSLog(@"Instance: %d", i);
    }
    
    // extract specific value...
    //NSArray *results = [res objectForKey:@"results"];
    
    //for (NSDictionary *result in results) {
        //NSString *icon = [result objectForKey:@"distance"];
        //NSLog(@"distance: %@", icon);
    //}
    
}

//-(void)setDataForPostView:(NSURL *)url {
//    
//    //NSString *filePath = _filePaths[0];
//    if (url != nil) {
//         _player = [[MPMoviePlayerController alloc] initWithContentURL:url];
//        [_player.view setFrame:_videoView.bounds];
//        [_player prepareToPlay];
//        [_player setShouldAutoplay:NO];
//    }else{
//        NSLog(@"File Not Saved Quick Enough!");
//    }
//    
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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

#pragma mark -
#pragma mark iCarousel methods

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    //return the total number of items in the carousel
    return 1;
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    UILabel *usernameLabel = nil;
    UILabel *pointLabel = nil;
    UIButton *reportUser = nil;
    UILabel *postTimeLabel = nil;
    UILabel *distanceLabel = nil;
    BFTDataHandler *handler = [BFTDataHandler sharedInstance];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:[_videoURLS objectAtIndex:index]] options:nil];
    
    
    //create new view if no view is available for recycling
//    if (view == nil)
//    {
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
        _videoView = [[UIView alloc] initWithFrame:CGRectMake(0,0, mainViewWidth, 220)];
        _videoView.backgroundColor = [UIColor colorWithRed:123/255.0 green:123/255.0 blue:123/255.0 alpha:1.0];
        _videoView.center = CGPointMake(100, 170);//170
        _videoView.tag = 20;
        [view addSubview:_videoView];
        
        
//        //AV Asset Player
//        AVPlayerItem * playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
//        _player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
//        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
//        playerLayer.frame = _videoView.bounds;
//        //        [playerLayer setFrame:_videoView.frame];
//        [_videoView.layer addSublayer:playerLayer];
//        [_player seekToTime:kCMTimeZero];
        
//        //Thumb Views
//        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, mainViewWidth, 220)];
//        imageView.center = CGPointMake(100, 170);
//        //[imageView setBackgroundColor:[UIColor colorWithWhite:100 alpha:1.0]];
//        imageView.tag = 200;
//        [imageView setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"v%lu", index + 1] ofType:@"jpg"]]];
//        [_videoView addSubview:imageView];
        
        
    
        
        //Username Display
        usernameLabel = [[UILabel alloc] initWithFrame:_videoView.bounds];
        usernameLabel.font = [usernameLabel.font fontWithSize:15];
        usernameLabel.textColor = [UIColor colorWithWhite:100 alpha:1.0];
        usernameLabel.center = CGPointMake(_videoView.center.x + 65, 270);
        usernameLabel.tag = 10;
        [mainView addSubview:usernameLabel];
        
        
        

//        //Play Button
//        _playButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60.0f, 60.0f)];
//        [_playButton setBackgroundImage:[UIImage imageNamed:@"play-icon-grey.png"] forState:UIControlStateNormal];
//        [_playButton addTarget:self action:@selector(postThread:) forControlEvents:UIControlEventTouchUpInside];
//        _playButton.center = CGPointMake(100, 160);
//        _playButton.tag = index;
//        [view addSubview:_playButton];
    
        
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
        
        
//    }
//    else
//    {
//        //get a reference to the label in the recycled view
//        _playButton = (UIButton *) [view viewWithTag:index];
//        //label = (UILabel *)[view viewWithTag:1];
//        usernameLabel = (UILabel *) [view viewWithTag:10];
//        pointLabel = (UILabel *) [view viewWithTag:12];
//        //imageView = (UIImageView *) [view viewWithTag:200];
//        _videoView = (UIView *) [view viewWithTag:20];
//    }
    
    //set item label
    //remember to always set any properties of your carousel item
    //views outside of the `if (view == nil) {...}` check otherwise
    //you'll get weird issues with carousel item content appearing
    //in the wrong place in the carousel
    //[playButton setBackgroundImage:[UIImage imageNamed:@"play-icon-grey.png"] forState:UIControlStateNormal];
    //label.text = [_items[index] stringValue];
    
    //AV Asset Player
    AVPlayerItem * playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
    _player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    playerLayer.frame = _videoView.bounds;
    //        [playerLayer setFrame:_videoView.frame];
    [_videoView.layer addSublayer:playerLayer];
    [_player seekToTime:kCMTimeZero];
    
    usernameLabel.text = handler.Username[index];
    pointLabel.text = @"32 points";
    postTimeLabel.text = @"3 hours ago";
    distanceLabel.text = @"4 miles away";
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishPlaying:) name:MPMoviePlayerPlaybackDidFinishNotification object:_player];

    return view;
}

-(void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index {
    if (index == _carousel.currentItemIndex) {
        [_player play];
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

-(IBAction)didFinishPlaying:(id)sender
{
    if (_playButton.isHidden) {
        [_playButton setHidden:NO];
    }else{
        [_playButton setHidden:YES];
        [_player play];
    }
}

-(void)playAtIndex:(NSInteger)index
{
}

-(IBAction)postThread:(id)sender {
    
    NSLog(@"Index Button Number: %ld", (long)[sender tag]);
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:[_videoURLS objectAtIndex:[sender tag]]] options:nil];
    //AV Asset Player
    AVPlayerItem * playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
    _player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    playerLayer.frame = _videoView.bounds;
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
