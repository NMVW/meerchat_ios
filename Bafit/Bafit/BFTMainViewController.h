//
//  BFTMainViewController.h
//  Bafit
//
//  Created by Keeano Martin on 7/23/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iCarousel.h"
#import "BFTMessageDelegate.h"
#import <MediaPlayer/MediaPlayer.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface BFTMainViewController : UIViewController <iCarouselDataSource, iCarouselDelegate, UINavigationControllerDelegate, BFTMessageDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate, UISearchBarDelegate>

@property (strong, nonatomic) UIView *videoPlayback;
@property (strong, nonatomic) IBOutlet UIView *customNavView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *forthButton;
@property (weak, nonatomic) IBOutlet UIButton *moveCatButton;
@property (strong, nonatomic) IBOutlet UIView *videoView;

// Not sure if playButton is being used anymore
@property (strong, nonatomic) IBOutlet UIButton *playButton;

@property (weak, nonatomic) IBOutlet UIButton *MessageCountLabel;


@property (nonatomic) int catagory;
@property (weak, nonatomic) NSArray *messages;
@property (nonatomic) BOOL swipeUp;
@property (nonatomic, strong) NSArray *tempHashTags;

@property (nonatomic) BOOL isRefreshing;

@property (nonatomic, strong) NSMutableDictionary *videoPlaybackControllers;
@property (nonatomic, assign) NSUInteger currentVideoPlaybackIndex;

@property (retain, nonatomic) IBOutlet iCarousel *carousel;
@property (retain, nonatomic) NSMutableArray *items;
@property(retain, nonatomic)  NSMutableOrderedSet *videoPosts;
@property (retain, nonatomic) NSMutableArray *imageObjects;
@property (weak, nonatomic)   NSMutableArray *filePaths;
@property (strong, nonatomic) NSMutableArray *mutableArray;
@property (strong, nonatomic) UILabel *usernameLabel;
@property (strong, nonatomic) NSArray *images;
@property (retain, nonatomic) AVPlayer *player;
@property (strong, nonatomic) UISwipeGestureRecognizer* swipeUpGestureRecognizer;
@property (assign, nonatomic) NSInteger segment;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

// pull to refresh elements
@property (strong, nonatomic) UIImageView *refresh;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *refreshGif;
@property (strong, nonatomic) IBOutlet UILabel *refreshingLbl;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingGif;

@property (nonatomic, strong) NSCache *tempImageCache;
@property (nonatomic, assign) BOOL notificationImageAssigned; //bool value to let me know whether or not the "you have new messages" image is on the back button or not

- (IBAction)SwipeDown:(UIGestureRecognizer *)recognizer;
- (IBAction)handleSwipeUp:(UIGestureRecognizer *)recognizer;
- (IBAction)postThread:(id)sender;
- (IBAction)backToThread:(id)sender;
- (IBAction)forthToPost:(id)sender;

// Get searchText for hashtag sort request to filter vids
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText;

// Temp variable to hold string while other activities happen
@property (nonatomic) NSString *hTagSearchTemp;
// Actual searched hashtag string
@property (nonatomic, strong) NSString *hTagSearch;

// Remove keyboard and take string input
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar;




@end
