//
//  BFTMeerPostViewController.m
//  Bafit
//
//  Created by Keeano Martin on 8/21/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTMeerPostViewController.h"

@interface BFTMeerPostViewController ()

@end

@implementation BFTMeerPostViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setPostToMainView];
    //set Naivagtion for View
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"appcoda-logo.png"]];

    //Switch handlers
    [_locationSwitch addTarget:self action:@selector(stateChangedLocation) forControlEvents:UIControlEventValueChanged];
    [_anonymousSwitch addTarget:self action:@selector(stateChangedUser) forControlEvents:UIControlEventValueChanged];
    
    //set state of lables
    [_userLabel setText:@"post anonymously"];
    [_locationLabel setText:@"hide location"];
    [_userLabel setTextColor:[UIColor colorWithWhite:0.50 alpha:1]];
    [_locationLabel setTextColor:[UIColor colorWithWhite:0.50 alpha:1]];
}

-(void)stateChangedLocation {
    if ([_locationSwitch isOn]) {
        //handle on
        _locationLabel.TextColor = [UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0];
        _locationLabel.Text = @"show location";
        //        [self.view addSubview:_locationLabel];
    }else{
        //handle off
        //color back to grey
        [_locationLabel setTextColor:[UIColor colorWithWhite:0.50 alpha:1]];
        _locationLabel.text =@"hide location";
    }
}

-(void)stateChangedUser {
    //Setup switches for privacy
     _data = [BFTDataHandler sharedInstance];
    if ([_anonymousSwitch isOn]) {
        //handle on
        _userLabel.TextColor = [UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0];
        _userLabel.Text = [NSString stringWithFormat:@"Post as %@", [_data BUN]];
        //        [self.view addSubview:_userLabel];
    }else{
        //handle off
        //color back to grey
        [_userLabel setTextColor:[UIColor colorWithWhite:0.50 alpha:1]];
        _userLabel.Text = @"post anonymously";
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setPostToMainView {

    _anonymousSwitch =[[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    _anonymousSwitch.transform = CGAffineTransformMakeScale(0.50f, 0.50f);
    [_anonymousSwitch setOnTintColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    _anonymousSwitch.center = CGPointMake(95, 453);
    [self.view addSubview:_anonymousSwitch];
    
    _locationSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    _locationSwitch.transform = CGAffineTransformMakeScale(0.50f, 0.50f);
    [_locationSwitch setOnTintColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    _locationSwitch.center = CGPointMake(95, 490);
    [self.view addSubview:_locationSwitch];
}

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
