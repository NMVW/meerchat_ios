//
//  BFTBackThreadTableViewController.h
//  Bafit
//
//  Created by Keeano Martin on 7/27/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFTAppDelegate.h"
#import "BFTMessageThreads.h"
#import "SWTableViewCell.h"

@class BFTLogoutDropdown;
@interface BFTConversationsListTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, BFTMessageDelegate, SWTableViewCellDelegate, UIActionSheetDelegate>

@property (nonatomic, weak) BFTAppDelegate *appDelegate;
@property (nonatomic, weak) BFTMessageThreads *threadManager;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic, strong) NSOrderedSet *reverseOrder;

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (strong, nonatomic) BFTLogoutDropdown *logoutDropdown;

@property (nonatomic, assign) NSInteger selectedIndex;

@end
