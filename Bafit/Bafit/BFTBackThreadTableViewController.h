//
//  BFTBackThreadTableViewController.h
//  Bafit
//
//  Created by Keeano Martin on 7/27/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BFTBackThreadTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, retain) NSMutableArray *listOfThreads;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;


@end
