//
//  BFTBackThreadTableViewController.m
//  Bafit
//
//  Created by Keeano Martin on 7/27/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTBackThreadTableViewController.h"
#import "BFTForthThreadControllerTableViewController.h"
#import "BFTThreadTableViewCell.h"
#import "BFTMainViewController.h"
#import "BFTBackThreadItem.h"
#import "BFTMessage.h"

#define UIColorFromRGB(rgbvalue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 168))/255.0 blue:((float)(rgbValue & 0xFF)) >> 166/255.0 alpha:1.0]

@interface BFTBackThreadTableViewController ()

@end

@implementation BFTBackThreadTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.threadManager = [BFTMessageThreads sharedInstance];
    
    self.appDelegate = (BFTAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    //actual background color for tableview
    UIView *backView = [[UIView alloc] initWithFrame:self.tableView.frame];
    [backView setBackgroundColor:[UIColor colorWithRed:240/255.0f green:240/255.0f blue:240/255.0f alpha:1]];
    [self.tableView setBackgroundView:backView];

    //remove seperator lines from searchbar
    //TODO:Uncomment these lines when adding search bar to remove seperator lines
    /*CGRect rect = self.searchBar.frame;
    UIView *bottomlineView = [[UIView alloc]initWithFrame:CGRectMake(0, rect.size.height -2, rect.size.width, 2)];
    bottomlineView.backgroundColor = [UIColor colorWithRed:240/255.0f green:240/255.0f blue:240/255.0f alpha:1];
    UIView *toplineView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, rect.size.width, 2)];
    toplineView.backgroundColor = [UIColor colorWithRed:240/255.0f green:240/255.0f blue:240/255.0f alpha:1];
    [self.searchBar addSubview:bottomlineView];
    [self.searchBar addSubview:toplineView];*/
    
    //custom nav bar
    [self.navigationController setNavigationBarHidden:NO animated:NO]; //not sure why we need to do this?
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed: 255/255.0 green:161/255.0 blue:0/255.0 alpha:1.0]];
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationItem setTitleView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"message_icon.png"]]];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    //hack to get an image where the right bar button goes
    UIBarButtonItem *miloFace = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"Milo_Face_Navbar.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]  style:UIBarButtonItemStylePlain target:self action:@selector(home:)];
    self.navigationItem.rightBarButtonItem = miloFace;
    
    [self.navigationItem setHidesBackButton:YES animated:NO];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterShortStyle;
    self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    [self.dateFormatter setDoesRelativeDateFormatting:YES];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [[BFTMessageThreads sharedInstance] resetUnread];
    self.appDelegate.messageDelegate = self;
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[BFTMessageThreads sharedInstance] resetUnread];
    self.appDelegate.messageDelegate = nil;
}

-(void)home:(UIBarButtonItem *)sender {
    [self performSegueWithIdentifier:@"backToMain" sender:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[_threadManager listOfThreads] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BFTThreadTableViewCell *cell = (BFTThreadTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"backThreadCell"];
    
    if (!cell) {
        cell = [[BFTThreadTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"backThreadCell"];
    }
    
    //Bold fonts
    [cell.usernameLabel setFont:[UIFont boldSystemFontOfSize:17]];
    [cell.numberMessagesLabel setFont:[UIFont boldSystemFontOfSize:17]];
    [cell.lastUpdatedLabel setFont:[UIFont boldSystemFontOfSize:17]];
    
    BFTBackThreadItem *item = [[_threadManager listOfThreads] objectAtIndex:indexPath.row];
    
    cell.usernameLabel.text = [NSString stringWithFormat:@"@%@", item.username];
    cell.numberMessagesLabel.text = [NSString stringWithFormat:@"%zd", [[item listOfMessages] count]];
    cell.lastUpdatedLabel.text = [self.dateFormatter stringFromDate:item.lastMessageTime];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.selectedIndex = indexPath.row;
    [self performSegueWithIdentifier:@"loadThread" sender:self];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_threadManager removeThreadAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark Messaging Delegate

-(void)recievedMessage:(NSString *)message fromSender:(NSString *)sender {
    //the actual recieving of the message is handled in the singleton, which we are getting are information from. we just need to reload the table data
    [self.tableView reloadData];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"loadThread"]) {
        BFTForthThreadControllerTableViewController *destination = [segue destinationViewController];
        
        BFTBackThreadItem *item = [[_threadManager listOfThreads] objectAtIndex:self.selectedIndex];
        destination.otherPersonsUserID = item.userID;
        destination.otherPersonsUserName = item.username;
        destination.messageThread = item;
    }
}


@end
