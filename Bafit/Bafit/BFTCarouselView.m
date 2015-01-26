//
//  BFTCarouselView.m
//  Bafit
//
//  Created by Joseph Pecoraro on 10/16/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTCarouselView.h"
#import "BFTConstants.h"

@implementation BFTCarouselView {
    BOOL _isDragging;
    CGPoint _oldPoint;
    
    CGRect _originalFrame;
}

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
    [self loadTopHalf];
    [self loadMiddleStuff];
    [self loadBottomHalf];
}

-(void)loadTopHalf {
    [self loadTopTrapezoid];
    [self loadRespondLabel];
    [self loadHastagLabel];
}

-(void)loadMiddleStuff {
    [self loadFacebookConnectionImage];
    [self loadMeerchatConnectionImage];
    [self loadUsernameLabel];
}

-(void)loadBottomHalf {
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
    self.responseButton = [[UIButton alloc] initWithFrame:CGRectMake(self.topTrapazoid.frame.origin.x, self.topTrapazoid.frame.origin.y, self.topTrapazoid.frame.size.width, self.topTrapazoid.frame.size.height/2)];
    
    [self.responseButton setTitle:@"respond" forState:UIControlStateNormal];
    [self.responseButton setTitleColor:kOrangeColor forState:UIControlStateNormal];
    [self.responseButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
    self.responseButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    //I shouldnt need this?
    self.responseButton.tag = 8;

    [self addSubview:self.responseButton];
}

-(void)loadHastagLabel {
    self.hashTagLabel = [[UILabel alloc] initWithFrame:CGRectOffset(self.responseButton.frame, 0, self.topTrapazoid.frame.size.height/2)];
    self.hashTagLabel.textColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    self.hashTagLabel.font = [self.hashTagLabel.font fontWithSize:14];
    self.hashTagLabel.textAlignment = NSTextAlignmentCenter;
    self.hashTagLabel.tag = 13;
    [self addSubview:self.hashTagLabel];
}

-(void)loadFacebookConnectionImage {
    self.facebookFriends = [[UIImageView alloc] initWithFrame:CGRectMake(5, self.topTrapazoid.frame.size.height + 5, 25, 25)];
    [self.facebookFriends setImage:[UIImage imageNamed:@"facebook_friend.png"]];
    [self.facebookFriends setContentMode:UIViewContentModeScaleAspectFit];
    [self addSubview:self.facebookFriends];
    [self.facebookFriends setHidden:YES];
}

-(void)loadMeerchatConnectionImage {
    self.meerchatConnection = [[UIImageView alloc] initWithFrame:CGRectMake(self.facebookFriends.frame.size.width + 5, self.topTrapazoid.frame.size.height + 5, 25, 25)];
    [self.meerchatConnection setImage:[UIImage imageNamed:@"meerchat_connected.png"]];
    [self.meerchatConnection setContentMode:UIViewContentModeScaleAspectFit];
    [self addSubview:self.meerchatConnection];
    [self.meerchatConnection setHidden:YES];
}

-(void)loadUsernameLabel {
    self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 258, self.frame.size.width, 30)];
    self.usernameLabel.font = [self.usernameLabel.font fontWithSize:16];
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
    self.locationIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"locationpin"]];
    [self.locationIcon setFrame:CGRectMake(10, 7, 20, 20)];
    [self.locationIcon setContentMode:UIViewContentModeScaleAspectFit];
    [self.bottomTrapazoid addSubview:self.locationIcon];
    
    self.distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.bottomTrapazoid.frame.origin.x + 2, self.bottomTrapazoid.frame.origin.y, self.bottomTrapazoid.frame.size.width/2 - (self.locationIcon.frame.size.width + self.locationIcon.frame.origin.x) - 8, self.bottomTrapazoid.frame.size.height/2)];
    self.distanceLabel.frame = CGRectOffset(self.distanceLabel.frame, self.locationIcon.frame.origin.x + self.locationIcon.frame.size.width, 0);
    self.distanceLabel.textColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    self.distanceLabel.font = [self.distanceLabel.font fontWithSize:9];
    self.distanceLabel.textAlignment = NSTextAlignmentCenter;
    self.distanceLabel.tag = 15;
    [self addSubview:self.distanceLabel];
}

-(void)loadTimeItems {
    self.timeIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"timeclock"]];
    [self.timeIcon setFrame:CGRectMake(self.bottomTrapazoid.frame.size.width/2 + 5, 10, 17, 17)];
    [self.timeIcon setContentMode:UIViewContentModeScaleAspectFit];
    [self.bottomTrapazoid addSubview:self.timeIcon];
    
    self.postTimeLabel = [[UILabel alloc] initWithFrame:CGRectOffset(self.distanceLabel.frame, self.distanceLabel.frame.size.width + self.timeIcon.frame.size.width + 12, 0)];
    self.postTimeLabel.textColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    self.postTimeLabel.font = [self.postTimeLabel.font fontWithSize:9];
    self.postTimeLabel.textAlignment = NSTextAlignmentCenter;
    self.postTimeLabel.tag = 14;
    [self addSubview:self.postTimeLabel];
}

-(void)loadNotTodayLabel {
    self.notTodayButton = [[UIButton alloc] initWithFrame:CGRectMake(self.bottomTrapazoid.frame.origin.x, self.bottomTrapazoid.frame.origin.y + self.bottomTrapazoid.frame.size.height/2, self.bottomTrapazoid.frame.size.width, self.bottomTrapazoid.frame.size.height/2)];
    
    [self.notTodayButton setTitle:@"not today" forState:UIControlStateNormal];
    [self.notTodayButton setTitleColor:kOrangeColor forState:UIControlStateNormal];
    [self.notTodayButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
    self.notTodayButton.titleLabel.textAlignment = NSTextAlignmentCenter;

    //Again, shouldnt need this?
    self.notTodayButton.tag = 11;

    [self addSubview:self.notTodayButton];
}

-(void)setVideoPlaybackView:(UIView *)videoPlaybackView {
    if (_videoPlaybackView) {
        [_videoPlaybackView removeFromSuperview];
    }
    _videoPlaybackView = videoPlaybackView;
    [self addSubview:_videoPlaybackView];
    [self bringSubviewToFront:self.usernameLabel];
    [self bringSubviewToFront:self.facebookFriends];
    [self bringSubviewToFront:self.meerchatConnection];
}

#pragma mark Touches
/* Allows the view to move around
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint location = [touch locationInView:touch.view];
    
    _isDragging = YES;
    _oldPoint = location;
    _originalFrame = self.frame;
    NSLog(@"Touches Began");
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_isDragging) {
        UITouch *touch = [[event allTouches] anyObject];
        CGPoint newPoint = [touch locationInView:touch.view];
        
        self.frame = CGRectOffset(self.frame, newPoint.x - _oldPoint.x, newPoint.y - _oldPoint.y);
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    _isDragging = NO;
    self.frame = _originalFrame;
    NSLog(@"Touches Ended");
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    _isDragging = NO;
    self.frame = _originalFrame;
    NSLog(@"Touches Cancelled");
}*/


@end
