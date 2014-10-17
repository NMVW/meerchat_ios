//
//  BFTCarouselView.m
//  Bafit
//
//  Created by Joseph Pecoraro on 10/16/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTCarouselView.h"

@implementation BFTCarouselView

-(instancetype)initWithFrame:(CGRect)frame {
    NSLog(@"initWithFrame is not currently implemented for this view");
    return [self init];
}

-(instancetype)init {
    self = [super initWithFrame:CGRectMake(0, 0, 216.0f, 360.0f)];
    if (self) {
        [self loadAllViewElements];
    }
    return self;
}

-(void)loadAllViewElements {
    [self loadTopTrapezoid];
    [self loadRespondLabel];
    [self loadHastagLabel];
    [self loadUsernameLabel];
    [self loadBottomTrapezoid];
    [self loadLocationItems];
    [self loadTimeItems];
    [self loadNotTodayLabel];
}

-(void)loadTopTrapezoid {
    self.topTrapazoid = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 72)];
    self.topTrapazoid.image = [UIImage imageNamed:@"trapezoid_menu_top.png"];
    self.topTrapazoid.tag = 4;
    [self addSubview:self.topTrapazoid];
}

-(void)loadRespondLabel {
    self.responseLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.topTrapazoid.frame.origin.x, self.topTrapazoid.frame.origin.y, self.topTrapazoid.frame.size.width, self.topTrapazoid.frame.size.height/2)];
    self.responseLabel.textColor = [UIColor colorWithRed:204/255.0f green:204/255.0f blue:204/255.0f alpha:1.0];
    self.responseLabel.font = [self.responseLabel.font fontWithSize:13];
    self.responseLabel.textAlignment = NSTextAlignmentCenter;
    self.responseLabel.tag = 8;
    self.responseLabel.text = @"respond";
    [self addSubview:self.responseLabel];
}

-(void)loadHastagLabel {
    self.hashTagLabel = [[UILabel alloc] initWithFrame:CGRectOffset(self.responseLabel.frame, 0, self.topTrapazoid.frame.size.height/2)];
    self.hashTagLabel.textColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    self.hashTagLabel.font = [self.hashTagLabel.font fontWithSize:11];
    self.hashTagLabel.textAlignment = NSTextAlignmentCenter;
    self.hashTagLabel.tag = 13;
    [self addSubview:self.hashTagLabel];
}

-(void)loadUsernameLabel {
    self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 258, self.frame.size.width, 30)];
    self.usernameLabel.font = [self.usernameLabel.font fontWithSize:15];
    self.usernameLabel.textColor = [UIColor colorWithWhite:100 alpha:1.0];
    self.usernameLabel.textAlignment = NSTextAlignmentCenter;
    self.usernameLabel.tag = 10;
    [self addSubview:self.usernameLabel];
}

-(void)loadBottomTrapezoid {
    self.bottomTrapazoid = [[UIImageView alloc] initWithFrame:CGRectMake(0, 288, self.frame.size.width, 72)];
    self.bottomTrapazoid.image = [UIImage imageNamed:@"trapezoid_menu_bottom_segmented.png"];
    self.bottomTrapazoid.tag = 6;
    self.bottomTrapazoid.contentMode = UIViewContentModeScaleToFill;
    [self addSubview:self.bottomTrapazoid];
}

-(void)loadLocationItems {
    self.locationIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"location_icon"]];
    [self.locationIcon setFrame:CGRectMake(10, 7, 20, 20)];
    [self.locationIcon setContentMode:UIViewContentModeScaleAspectFit];
    [self.bottomTrapazoid addSubview:self.locationIcon];
    
    self.distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.bottomTrapazoid.frame.origin.x, self.bottomTrapazoid.frame.origin.y, self.bottomTrapazoid.frame.size.width/2 - (self.locationIcon.frame.size.width + self.locationIcon.frame.origin.x), self.bottomTrapazoid.frame.size.height/2)];
    self.distanceLabel.frame = CGRectOffset(self.distanceLabel.frame, self.locationIcon.frame.origin.x + self.locationIcon.frame.size.width, 0);
    self.distanceLabel.textColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    self.distanceLabel.font = [self.distanceLabel.font fontWithSize:9];
    self.distanceLabel.textAlignment = NSTextAlignmentLeft;
    self.distanceLabel.tag = 15;
    [self addSubview:self.distanceLabel];
}

-(void)loadTimeItems {
    self.timeIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"clock_icon"]];
    [self.timeIcon setFrame:CGRectMake(self.bottomTrapazoid.frame.size.width/2 + 5, 7, 17, 17)];
    [self.timeIcon setContentMode:UIViewContentModeScaleAspectFit];
    [self.bottomTrapazoid addSubview:self.timeIcon];
    
    self.postTimeLabel = [[UILabel alloc] initWithFrame:CGRectOffset(self.distanceLabel.frame, self.distanceLabel.frame.origin.x + self.distanceLabel.frame.size.width, 0)];
    self.postTimeLabel.textColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    self.postTimeLabel.font = [self.postTimeLabel.font fontWithSize:9];
    self.postTimeLabel.textAlignment = NSTextAlignmentLeft;
    self.postTimeLabel.tag = 14;
    [self addSubview:self.postTimeLabel];
}

-(void)loadNotTodayLabel {
    self.notTodayLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.bottomTrapazoid.frame.origin.x, self.bottomTrapazoid.frame.origin.y + self.bottomTrapazoid.frame.size.height/2, self.bottomTrapazoid.frame.size.width, self.bottomTrapazoid.frame.size.height/2)];
    self.notTodayLabel.textColor = [UIColor colorWithRed:204/255.0f green:204/255.0f blue:204/255.0f alpha:1.0];
    self.notTodayLabel.font = [self.notTodayLabel.font fontWithSize:13];
    self.notTodayLabel.textAlignment = NSTextAlignmentCenter;
    self.notTodayLabel.tag = 11;
    self.notTodayLabel.text = @"not today";
    [self addSubview:self.notTodayLabel];
}

-(void)setVideoPlaybackView:(UIView *)videoPlaybackView {
    if (_videoPlaybackView) {
        [_videoPlaybackView removeFromSuperview];
    }
    _videoPlaybackView = videoPlaybackView;
    [self addSubview:_videoPlaybackView];
    [self bringSubviewToFront:self.usernameLabel];
}

@end
