//
//  BFTBackThreadTableViewController.m
//  Bafit
//
//  Created by Keeano Martin on 7/27/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTConversationsListTableViewController.h"
#import "BFTMessageThreadTableViewController.h"
#import "BFTThreadTableViewCell.h"
#import "BFTMainViewController.h"
#import "BFTLogoutDropdown.h"
#import "BFTBackThreadItem.h"
#import "BFTMessage.h"
#import "BFTConstants.h"
#import "SDImageCache.h"
#import "BFTDatabaseRequest.h"
#import "BFTDataHandler.h"

#define UIColorFromRGB(rgbvalue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 168))/255.0 blue:((float)(rgbValue & 0xFF)) >> 166/255.0 alpha:1.0]

@interface BFTConversationsListTableViewController ()

@property (nonatomic, strong) UILabel *noMessagesLabel;

@end

@implementation BFTConversationsListTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.threadManager = [BFTMessageThreads sharedInstance];
    
    self.appDelegate = (BFTAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    //actual background color for tableview
    UIView *backView = [[UIView alloc] initWithFrame:self.tableView.frame];
    [backView setBackgroundColor:[UIColor colorWithRed:240/255.0f green:240/255.0f blue:240/255.0f alpha:1]];
    [self.tableView setBackgroundView:backView];
    
    _noMessagesLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, [UIScreen mainScreen].bounds.size.width - 40, 150)];
    [_noMessagesLabel setText:@"You haven’t started talking to anyone! Respond to a public post or create a public post to get things started. Once you have exchanged video messages, you will be able to chat here."];
    [_noMessagesLabel setNumberOfLines:5];
    [_noMessagesLabel setTextAlignment:NSTextAlignmentCenter];
    [_noMessagesLabel setFont:[UIFont systemFontOfSize:16]];
    [_noMessagesLabel setTextColor:[UIColor lightGrayColor]];
    
    [self.tableView addSubview:_noMessagesLabel];
    
    [_noMessagesLabel setHidden:YES];

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
    [self.navigationItem setTitleView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"msg_center.png"]]];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    //hack to get an image where the right bar button goes
    UIBarButtonItem *miloFace = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"milo_backtohome.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]  style:UIBarButtonItemStylePlain target:self action:@selector(home:)];
    self.navigationItem.rightBarButtonItem = miloFace;
    
    UIBarButtonItem *facebookLogout = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"facebook_friend"] style:UIBarButtonItemStylePlain target:self action:@selector(showDropDown)];
    
    [self.navigationItem setLeftBarButtonItem:facebookLogout];
    
    self.logoutDropdown = [[BFTLogoutDropdown alloc] init];
    //set facebook friends button stuff
    [self.logoutDropdown.logoutButton addTarget:self action:@selector(logoutOfApp) forControlEvents:UIControlEventTouchUpInside];
    [self.logoutDropdown.inviteFriendsButton addTarget:self action:@selector(inviteFacebookFriends) forControlEvents:UIControlEventTouchUpInside];
    [[[[UIApplication sharedApplication] delegate] window] addSubview:self.logoutDropdown];
    self.logoutDropdown.hidden = YES;
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterShortStyle;
    self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    [self.dateFormatter setDoesRelativeDateFormatting:YES];
    
    UIView *footerView  = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.0, 0)];
    footerView.backgroundColor = [UIColor clearColor];
    self.tableView.tableFooterView = footerView;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // order conversations by time/date - just need to reverse the "listOfThreads" set
    self.reverseOrder = [_threadManager listOfThreads].reversedOrderedSet;
    [self.tableView reloadData];
    self.appDelegate.messageDelegate = self;
    [[BFTMessageThreads sharedInstance] saveThreads];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.logoutDropdown setHidden:YES];//should animate this
    [[BFTMessageThreads sharedInstance] resetUnread];
    self.appDelegate.messageDelegate = nil;
}

-(void)home:(UIBarButtonItem *)sender {
    [self performSegueWithIdentifier:@"backToMain" sender:self];
}

-(void)showDropDown {
    [self.logoutDropdown setHidden:!self.logoutDropdown.hidden];
}

-(void)logoutOfApp {
    [self.appDelegate logout];
    [self performSegueWithIdentifier:@"logoutToFacebook" sender:self];
}

-(void)inviteFacebookFriends {
    FBLinkShareParams *params = [[FBLinkShareParams alloc] init];
    params.link = [NSURL URLWithString:kAppLink];
    
    if ([FBDialogs canPresentShareDialogWithParams:params] || [FBDialogs canPresentOSIntegratedShareDialog]) {
        [FBDialogs presentShareDialogWithLink:params.link handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
            if(error) {
                NSLog(@"Error: %@", error.description);
            } else {
                NSLog(@"Success: %@\n%@", call, results);
            }
        }];
    }
    else {
        // Put together the dialog parameters
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"359513137551945", @"app_id",
                                       @"Join Me on Meerchat", @"name",
                                       @"Meet people in a new way.", @"caption",
                                       kAppLink, @"link",
                                       @"https://scontent-b-mia.xx.fbcdn.net/hphotos-xpf1/t31.0-8/10371180_313059045533978_5323915247316406367_o.png", @"picture",
                                       nil];
        
        // Show the feed dialog
        [FBWebDialogs presentFeedDialogModallyWithSession:[FBSession activeSession] parameters:params handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
            if (error) {
                // An error occurred, we need to handle the error
                // See: https://developers.facebook.com/docs/ios/errors
                NSLog(@"Error publishing story: %@", error.description);
            } else {
                if (result == FBWebDialogResultDialogNotCompleted) {
                    // User cancelled.
                    NSLog(@"User cancelled.");
                } else {
                    // Handle the publish feed callback
                    NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                    
                    if (![urlParams valueForKey:@"post_id"]) {
                        // User cancelled.
                        NSLog(@"User cancelled.");
                        
                    } else {
                        // User clicked the Share button
                        NSString *result = [NSString stringWithFormat: @"Posted story, id: %@", [urlParams valueForKey:@"post_id"]];
                        NSLog(@"result %@", result);
                    }
                }
            }
        }];

    }
}

// A function for parsing URL parameters returned by the Feed Dialog.
- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    return params;
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
    NSInteger numberOfItems = [[_threadManager listOfThreads] count];
    if (numberOfItems == 0) {
        [_noMessagesLabel setHidden:NO];
    }
    else {
        [_noMessagesLabel setHidden:YES];
    }
    return numberOfItems;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 52;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BFTThreadTableViewCell *cell = (BFTThreadTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"backThreadCell"];
    
    if (!cell) {
        cell = [[BFTThreadTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"backThreadCell"];
    }
    
    // set Delete and Block slide out buttons
    [cell setRightUtilityButtons:[self rightButtons] WithButtonWidth:78.0f];
    cell.delegate = self;
    
    //Bold fonts
    [cell.usernameLabel setFont:[UIFont boldSystemFontOfSize:16]];
    [cell.numberMessagesLabel setFont:[UIFont boldSystemFontOfSize:16]];
    [cell.lastUpdatedLabel setFont:[UIFont boldSystemFontOfSize:14]];
    
    
    BFTBackThreadItem *item = [self.reverseOrder objectAtIndex:indexPath.row];
    
    cell.usernameLabel.text = [NSString stringWithFormat:@"@%@", item.username];
    cell.numberMessagesLabel.text = [item numberUnreadMessages] == 0 ? @"" : [NSString stringWithFormat:@"%zd", [item numberUnreadMessages]];
    cell.lastUpdatedLabel.text = [self.dateFormatter stringFromDate:item.lastMessageTime];
    
    if (item.messagesUnseen) {
        [cell.usernameLabel setTextColor:kOrangeColor];
        [cell.numberMessagesLabel setTextColor:kOrangeColor];
        [cell.lastUpdatedLabel setTextColor:kOrangeColor];
    }
    else {
        [cell.usernameLabel setTextColor:[UIColor lightGrayColor]];
        [cell.numberMessagesLabel setTextColor:[UIColor lightGrayColor]];
        [cell.lastUpdatedLabel setTextColor:[UIColor lightGrayColor]];
    }
    
    //Image
    NSString* thumbURL = [[NSString alloc] initWithFormat:@"http://graph.facebook.com/%@/picture?type=large", item.facebookID];
    [cell.thumbnail setImage:[[SDImageCache sharedImageCache] imageFromDiskCacheForKey:thumbURL]];
    
    if (!cell.thumbnail.image) {
        [[[BFTDatabaseRequest alloc] initWithFileURL:thumbURL completionBlock:^(NSMutableData *data, NSError *error) {
            if (!error) {
                UIImage *image = [UIImage imageWithData:data];
                
                [[SDImageCache sharedImageCache] storeImage:image forKey:thumbURL];
                [cell.thumbnail setImage:image];
            }
            else {
                //handle image download error
            }
        }] startImageDownload];
    }
    
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

//remove tableview seperator inset
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)])
    {
        if (indexPath.section == 0)
        {
            [cell setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 0)];
        }
        else
        {
            [cell setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 0)];
        }
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)])
    {
        [cell setLayoutMargins:UIEdgeInsetsMake(0, 0, 0, 0)];
    }
}

//remove tableview seperator inset
-(void)viewDidLayoutSubviews
{
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)])
    {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 0)];
    }
    
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)])
    {
        [self.tableView setLayoutMargins:UIEdgeInsetsMake(0, 0, 0, 0)];
    }
}

#pragma mark - SWTableViewDelegate
// table cell edit buttons
- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0]
                                                title:@"Block"];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:@"Delete"];
    
    return rightUtilityButtons;
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
        {
            NSLog(@"More button was pressed");
            NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
            
            UIActionSheet *actSheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure you want to report this user? You will no longer recieve any updates from them." delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Block User" otherButtonTitles:nil];
            [actSheet setTag:cellIndexPath.row];
            [actSheet showInView:self.view];
            
            //[cell hideUtilityButtonsAnimated:YES];
            break;
        }
        case 1:
        {
            // Delete button was pressed
            NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
            
            BFTBackThreadItem *item = [self.reverseOrder objectAtIndex:cellIndexPath.row];
            
            NSUInteger itemIndex = [_threadManager.listOfThreads indexOfObject:item];
            
            [_threadManager removeThreadAtIndex:itemIndex];
            [self.tableView deleteRowsAtIndexPaths:@[cellIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            break;
        }
        default:
            break;
    }
}

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell
{
    // allow just one cell's utility button to be open at once
    return YES;
}

- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state
{
    switch (state) {
        case 1:
            // set to NO to disable all left utility buttons appearing
            return NO;
            break;
        case 2:
            // set to NO to disable all right utility buttons appearing
            return YES;
            break;
        default:
            break;
    }
    
    return YES;
}

#pragma mark Messaging Delegate

-(void)recievedMessage {
    //the actual recieving of the message is handled in the singleton, which we are getting are information from. we just need to reload the table data
    self.reverseOrder = [_threadManager listOfThreads].reversedOrderedSet;
    [self.tableView reloadData];
}

#pragma mark - Action Sheet

-(void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self performSelectorOnMainThread:@selector(blockUser:) withObject:[NSNumber numberWithInteger:actionSheet.tag] waitUntilDone:NO];
    }
    return;
}

#pragma mark - Buttons

-(void)blockUser:(NSNumber *)rowIndex {
    NSInteger index = [rowIndex integerValue];
    
    BFTBackThreadItem *user = [self.reverseOrder objectAtIndex:index];
    
    [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"blockUser.php?UIDr=%@&UIDp=%@&GPSlat=%.4f&GPSlon=%.4f", [[BFTDataHandler sharedInstance] FBID], user.facebookID, [[BFTDataHandler sharedInstance] Latitude], [[BFTDataHandler sharedInstance] Longitude]] trueOrFalseBlock:^(BOOL success, NSError *error) {
        if (!error) {
            // remove user message from thread manager and reload table
            BFTBackThreadItem *user = [self.reverseOrder objectAtIndex:index];
            [[_threadManager listOfThreads] removeObject:user];
            
            //self.reverseOrder = nil;
            self.reverseOrder = [_threadManager listOfThreads].reversedOrderedSet;
            
            [self.tableView reloadData];
            
            // add remove table cell code
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"Could not block user" message:error.localizedDescription delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        }
    }] startConnection];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"loadThread"]) {
        UINavigationController *navController = [segue destinationViewController];
        BFTMessageThreadTableViewController *destination = [navController.viewControllers objectAtIndex:0];
        
        BFTBackThreadItem *item = [self.reverseOrder objectAtIndex:self.selectedIndex];
        destination.otherPersonsUserID = item.userID;
        destination.otherPersonsUserName = item.username;
        destination.messageThread = item;
    }
}

@end
