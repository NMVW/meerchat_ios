//
//  BFTLogoutDropdown.m
//  Bafit
//
//  Created by Joseph Pecoraro on 12/16/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTLogoutDropdown.h"
#import "UIImage+Color.h"
#import "BFTConstants.h"
#import "BFTDataHandler.h"
#import "SDImageCache.h"
#import "BFTDatabaseRequest.h"

@implementation BFTLogoutDropdown

-(instancetype)init {
    self = [super initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, 140.0f)];
    if (self) {
        [self loadView];
    }
    return self;
}

-(void)loadView {
    [self setBackgroundColor:[UIColor whiteColor]];
    //I don't think we need the close button
    //[self loadCloseButton];
    [self loadInviteFriendsButton];
    [self loadLogoutButton];
    [self loadBottomBorder];
    [self loadProfilePicture];
    [self loadUsernameLabels];
    [self setUserInteractionEnabled:YES];
}

-(void)loadCloseButton {
    self.closeButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, 24, 24)];
    [self.closeButton setImage:[UIImage imageNamed:@"close.png"] forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(hideView) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:self.closeButton];
}

-(void)loadProfilePicture {
    self.profilePicture = [[UIImageView alloc] initWithFrame:CGRectMake(self.inviteFriendsButton.frame.origin.x + self.inviteFriendsButton.frame.size.width - 75, 14, 60, 60)];
    //self.profilePicture = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width/4-30, 14, 60, 60)];
    [self.profilePicture setContentMode:UIViewContentModeScaleAspectFill];
    [self.profilePicture.layer setCornerRadius:5];
    [self.profilePicture setClipsToBounds:YES];
    
    NSString* thumbURL = [[NSString alloc] initWithFormat:@"http://graph.facebook.com/%@/picture?type=large", [[BFTDataHandler sharedInstance] FBID]];
    [self.profilePicture setImage:[[SDImageCache sharedImageCache] imageFromDiskCacheForKey:thumbURL]];

    if (!self.profilePicture.image) {
        [[[BFTDatabaseRequest alloc] initWithFileURL:thumbURL completionBlock:^(NSMutableData *data, NSError *error) {
            if (!error) {
                UIImage *image = [UIImage imageWithData:data];
                
                [[SDImageCache sharedImageCache] storeImage:image forKey:thumbURL];
                [self.profilePicture setImage:image];
            }
            else {
                //handle image download error
            }
        }] startImageDownload];
    }
    
    [self addSubview:self.profilePicture];
}

-(void)loadUsernameLabels {
    self.loggedInLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.profilePicture.frame.origin.x + self.profilePicture.frame.size.width + 10, self.profilePicture.frame.origin.y + 5, [UIScreen mainScreen].bounds.size.width - self.profilePicture.frame.origin.x, 25)];
    [self.loggedInLabel setFont:[UIFont systemFontOfSize:16]];
    [self.loggedInLabel setTextColor:[UIColor lightGrayColor]];
    [self.loggedInLabel setText:@"Logged in as:"];
    
    self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectOffset(self.loggedInLabel.frame, 0, self.loggedInLabel.frame.size.height)];
    [self.usernameLabel setFont:[UIFont systemFontOfSize:16]];
    [self.usernameLabel setTextColor:[UIColor lightGrayColor]];
    [self.usernameLabel setText:[NSString stringWithFormat:@"%@ %@", [[BFTDataHandler sharedInstance] firstName] ?: @"", [[BFTDataHandler sharedInstance] lastName] ?: @""]];
    
    [self addSubview:self.loggedInLabel];
    [self addSubview:self.usernameLabel];
}

-(void)loadInviteFriendsButton {
    self.inviteFriendsButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width/4 - 60, self.frame.size.height-20-30, 120, 31)];
    [self.inviteFriendsButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
    [self.inviteFriendsButton setTitle:@"Share Meerchat" forState:UIControlStateNormal];
    [self.inviteFriendsButton setBackgroundImage:[UIImage imageWithColor:[UIColor lightGrayColor]] forState:UIControlStateNormal];
    [self.inviteFriendsButton setBackgroundImage:[UIImage imageWithColor:[UIColor grayColor]] forState:UIControlStateHighlighted];
    [self.inviteFriendsButton setBackgroundImage:[UIImage imageWithColor:[UIColor grayColor]] forState:UIControlStateSelected];
    
    [self.inviteFriendsButton.layer setCornerRadius:4];
    [self.inviteFriendsButton.layer setMasksToBounds:YES];
    
    [self addSubview:self.inviteFriendsButton];
}

-(void)loadLogoutButton {
    self.logoutButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width/4*3-60, self.frame.size.height-20-30, 120, 31)];
    [self.logoutButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
    [self.logoutButton setTitle:@"Logout" forState:UIControlStateNormal];
    [self.logoutButton setBackgroundImage:[UIImage imageWithColor:[UIColor lightGrayColor]] forState:UIControlStateNormal];
    [self.logoutButton setBackgroundImage:[UIImage imageWithColor:[UIColor grayColor]] forState:UIControlStateHighlighted];
    [self.logoutButton setBackgroundImage:[UIImage imageWithColor:[UIColor grayColor]] forState:UIControlStateSelected];
    
    [self.logoutButton.layer setCornerRadius:4];
    [self.logoutButton.layer setMasksToBounds:YES];
    
    [self addSubview:self.logoutButton];
}

-(void)loadBottomBorder {
    [self.layer setShadowPath:[[UIBezierPath bezierPathWithRoundedRect:self.layer.bounds cornerRadius:2] CGPath]];
    [self.layer setShadowColor:[UIColor lightGrayColor].CGColor];
    [self.layer setShadowOpacity:1];
    [self.layer setShadowRadius:2];
    [self.layer setShadowOffset:CGSizeMake(0, 2)];
}

-(void)hideView {
    [self setHidden:!self.hidden];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
