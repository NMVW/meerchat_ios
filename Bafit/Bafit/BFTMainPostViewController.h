//
//  BFTMeerPostViewController.h
//  Bafit
//
//  Created by Keeano Martin on 8/21/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iCarousel.h"
#import "BFTDataHandler.h"
#import "BFTCameraView.h"
#import "BFTCameraViewDelegate.h"
#import "BFTVideoPlaybackController.h"

@protocol BFTCameraViewDelegate;

@interface BFTMainPostViewController : UIViewController <BFTCameraViewDelegate, UINavigationBarDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (strong, nonatomic) IBOutlet UIImageView *btmTrapazoid;

@property (strong, nonatomic) BFTDataHandler *data;
@property (strong, nonatomic) IBOutlet UIView *recordView;
@property (strong, nonatomic) BFTCameraView *embeddedRecordView;
@property (nonatomic, assign) BOOL postFromView;
@property (nonatomic, assign) NSString *mp4Name;
@property (nonatomic, weak) NSString *MessageCount;
@property (strong, nonatomic) IBOutlet UILabel *categoryLabel;
@property (strong, nonatomic) IBOutlet UITextField *hashtagEditText;
@property (strong, nonatomic) IBOutlet UIButton *moveButton;
@property (strong, nonatomic) IBOutlet UIButton *grubButton;
@property (strong, nonatomic) IBOutlet UIButton *loveButton;
@property (strong, nonatomic) IBOutlet UIButton *studyButton;

@property (strong, nonatomic) IBOutlet UIView *cardView;

@property (strong, nonatomic) IBOutlet UIView *postBtnView;
@property (strong, nonatomic) IBOutlet UIButton *postBtn;
@property (strong, nonatomic) IBOutlet UIButton *clearBtn;

// bar button to dismiss keyboard after inputting hashtags
@property (strong, nonatomic) IBOutlet UIBarButtonItem *dismiss;
@property (strong, nonatomic) IBOutlet UINavigationItem *navItem;

@property (nonatomic) BOOL postBtnColorOrange;
@property (nonatomic) BOOL canPost;

-(void)popVC;
- (IBAction)clearBtnClicked:(id)sender;
- (IBAction)postBtnClicked:(id)sender;

- (IBAction)moveClicked:(id)sender;
- (IBAction)grubClicked:(id)sender;
- (IBAction)loveClicked:(id)sender;
- (IBAction)studyClicked:(id)sender;
- (IBAction)updateHashtag:(id)sender;


@end
