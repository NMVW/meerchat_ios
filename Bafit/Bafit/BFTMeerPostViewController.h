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

@protocol MeerPostDelegate <NSObject>
@optional

-(void)doneSavingAtURL:(NSString *)url;

@end


@interface BFTMeerPostViewController : UIViewController
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (strong, nonatomic) IBOutlet UIImageView *btmTrapazoid;
@property (strong, nonatomic) IBOutlet UILabel *userLabel;
@property (strong, nonatomic) IBOutlet UILabel *locationLabel;
@property (strong, nonatomic) UISwitch *anonymousSwitch;
@property (strong, nonatomic) UISwitch *locationSwitch;
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

-(void)uploadToMain;

- (IBAction)moveClicked:(id)sender;
- (IBAction)grubClicked:(id)sender;
- (IBAction)loveClicked:(id)sender;
- (IBAction)studyClicked:(id)sender;
- (IBAction)updateHashtag:(id)sender;


@end
