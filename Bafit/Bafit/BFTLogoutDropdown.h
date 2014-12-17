//
//  BFTLogoutDropdown.h
//  Bafit
//
//  Created by Joseph Pecoraro on 12/16/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BFTLogoutDropdown : UIView

@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIImageView *profilePicture;
@property (nonatomic, strong) UILabel *loggedInLabel;
@property (nonatomic, strong) UILabel *usernameLabel;

@property (nonatomic, strong) UIButton *inviteFriendsButton;
@property (nonatomic, strong) UIButton *logoutButton;

@property (nonatomic, strong) UIView *bottomBorder;

@end
