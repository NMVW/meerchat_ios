//
//  BFTBackThreadTableViewController.m
//  Bafit
//
//  Created by Keeano Martin on 7/27/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTBackThreadTableViewController.h"
#import "BFTThreadTableViewCell.h"
#import "BFTMainViewController.h"
#import "BFTMessage.h"

#define UIColorFromRGB(rgbvalue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 168))/255.0 blue:((float)(rgbValue & 0xFF)) >> 166/255.0 alpha:1.0]

@interface BFTBackThreadTableViewController ()

@end

@implementation BFTBackThreadTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //Naivagation Bar
    [self.navigationController setNavigationBarHidden:NO  animated:NO];
    //UIEdgeInsets inset = UIEdgeInsetsMake(56, 0, 0, 0);
    //self.tableView.contentInset = inset;
    //[self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed: 88/255.0 green:168/255.0 blue:166/255.0 alpha:1.0]];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav-bar@2x.png"] forBarMetrics:UIBarMetricsDefault];
    self.title = @"";
    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(home:)];
    self.navigationItem.leftBarButtonItem = newBackButton;
    
    _dummyUsers = [[NSArray alloc] initWithObjects:@"@JonathanB",@"@NickyV",@"@Dman",@"C-LO-P",@"Auginator",@"Mcgurn1", nil];
    _messageTimes = [[NSArray alloc] initWithObjects:@"3:34 PM",@"5:12 AM",@"Yesterday",@"3 days ago",@"2 weeks ago",@"3 weeks ago", nil];
    _numberOfMessages = [[NSArray alloc] initWithObjects:@"1",@"3",@"",@"",@"",@"", nil];
    NSLog(@"%lu", (unsigned long)[_dummyUsers count]);
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)home:(UIBarButtonItem *)sender {
    NSLog(@"%@", self.navigationController);
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [_dummyUsers count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BFTThreadTableViewCell *cell = (BFTThreadTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"CellIdentifier"];
    // Configure the cell
    cell.userLabel.text = [_dummyUsers objectAtIndex:[indexPath row]];
    [cell.numberMessageThread setTitle:[_numberOfMessages objectAtIndex:[indexPath row]] forState:UIControlStateNormal];
    [cell setBackgroundColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    cell.timeStamp.text = [_messageTimes objectAtIndex:[indexPath row]];
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
