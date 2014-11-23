//
//  BFTCarouselView.h
//  Bafit
//
//  Created by Joseph Pecoraro on 10/16/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BFTCarouselView : UIView

@property (nonatomic, strong) UIImageView *topTrapazoid;
@property (nonatomic, strong) UIButton *responseButton;
@property (nonatomic, strong) UILabel *hashTagLabel;

@property (nonatomic, strong) UIView *videoPlaybackView;
@property (nonatomic, strong) UILabel *usernameLabel;

@property (nonatomic, strong) UIImageView *bottomTrapazoid;

@property (nonatomic, strong) UIImageView *locationIcon;
@property (nonatomic, strong) UILabel *distanceLabel;

@property (nonatomic, strong) UIImageView *timeIcon;
@property (nonatomic, strong) UILabel *postTimeLabel;
@property (nonatomic, strong) UIButton *notTodayButton;

@end
