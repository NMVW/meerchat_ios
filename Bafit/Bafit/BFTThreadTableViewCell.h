//
//  BFTThreadTableViewCell.h
//  Bafit
//
//  Created by Keeano Martin on 7/27/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"

// SWTableViewCell allows for a custom edit view with multiple button... UITableViewCell only allows 1 edit button "legally" (w/o using a private API)

@interface BFTThreadTableViewCell : SWTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *numberMessagesLabel;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastUpdatedLabel;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnail;


@end
