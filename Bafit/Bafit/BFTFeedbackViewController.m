//
//  BFTFeedbackViewController.m
//  Bafit
//
//  Created by Joseph Pecoraro on 8/24/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTFeedbackViewController.h"
#import "BFTDatabaseRequest.h"
#import "BFTDataHandler.h"
#import "BFTConstants.h"

@interface BFTFeedbackViewController () <UIPickerViewDataSource, UIPickerViewDelegate, UITextViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *issuesExperiencedLabel;
@property (weak, nonatomic) IBOutlet UIPickerView *issuesPickerView;
@property (weak, nonatomic) IBOutlet UITextView *issuesDetailTextView;
@property (weak, nonatomic) IBOutlet UITextView *commentsFeedbackTextView;
@property (weak, nonatomic) IBOutlet UILabel *issuesLabel;
@property (weak, nonatomic) IBOutlet UISwitch *recommendSwitch;

@end

@implementation BFTFeedbackViewController {
    BOOL _datePickerShowing;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.issuesExperiencedLabel setFont:[UIFont boldSystemFontOfSize:16]];
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelSubmission:)];
    UIBarButtonItem *submit = [[UIBarButtonItem alloc] initWithTitle:@"Submit" style:UIBarButtonItemStyleBordered target:self action:@selector(submitForm:)];
    
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed: 255/255.0 green:161/255.0 blue:0/255.0 alpha:1.0]];
    [self.navigationItem setTitle:@"Feedback"];
    [self.navigationItem setLeftBarButtonItem:cancel];
    [self.navigationItem setRightBarButtonItem:submit];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
}

#pragma mark Table View

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;//section == 2 ? 35 : 0.01f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;//section == 2 ? 35 : 0.01f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 3) {
        return 60;
    }
    else if (indexPath.section == 2) {
        return 50;
    }
    else if (indexPath.section == 1) {
        return 220;
    }
    else {
        if (indexPath.row == 0) {
            return 44;
        }
        else if (indexPath.row == 1) {
            if (!_datePickerShowing) {
                return 0;
            }
            else {
                return 140;
            }
        }
        else {
            return 140;
        }
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0 && indexPath.row == 0) {
        [self.tableView beginUpdates];
        _datePickerShowing = !_datePickerShowing;
        [self.tableView endUpdates];
    }
}

#pragma mark Pivker View items

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 7;
}

-(NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    switch (row) {
        case 0:
            return @"Interface";
            break;
        case 1:
            return @"Data Loss";
            break;
        case 2:
            return @"Video Playback";
            break;
        case 3:
            return @"Messaging";
            break;
        case 4:
            return @"Location Based";
            break;
        case 5:
            return @"Other";
            break;
        case 6:
            return @"None";
            break;
    }
    return nil;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.issuesLabel.text = [self pickerView:pickerView titleForRow:row forComponent:component];
}

#pragma mark Text View

static NSString *issuePlaceholder = @"Further Details...";
static NSString *feedbackPlaceholder = @"Additional Feedback...";

//limiting character range
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    NSInteger length = [newText length];
    if ([textView isEqual:self.issuesDetailTextView]) {
        return length < 220 ? YES : NO;
    }
    else {
        return length < 550 ? YES : NO;
    }
}

//make textview text placeholder
-(BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if ([textView isEqual:self.commentsFeedbackTextView]) {
        if ([[textView text] isEqualToString:feedbackPlaceholder]) {
            textView.text = @"";
            textView.textColor = [UIColor grayColor];
        }
    }
    else {
        if ([[textView text] isEqualToString:issuePlaceholder]) {
            textView.text = @"";
            textView.textColor = [UIColor grayColor];
        }
    }
    
    return YES;
}

-(BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    if ([textView isEqual:self.commentsFeedbackTextView]) {
        if ([[textView text] length] == 0) {
            textView.text = feedbackPlaceholder;
            textView.textColor = [UIColor lightGrayColor];
        }
    }
    else {
        if ([[textView text] length] == 0) {
            textView.text = issuePlaceholder;
            textView.textColor = [UIColor lightGrayColor];
        }
    }
    return YES;
}

#pragma mark Scroll View

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

#pragma mark Alert View

-(void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:@"Thank you for your feedback!"]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)submitForm:(id)sender {
    BFTDataHandler *handler = [BFTDataHandler sharedInstance];
    NSString *url = [[NSString alloc] initWithFormat:@"sendFeedback.php?issue=%@&issueDetail=%@&contFeedback=%@&recommend=%@&UID=%@&BUN=%@&lat=%.4f&lon=%.4f", self.issuesLabel.text, self.issuesDetailTextView.text, self.commentsFeedbackTextView.text, [self.recommendSwitch isOn] ? @"YES" : @"NO", [handler UID], [handler BUN], [handler Latitude], [handler Longitude]];
    [[[BFTDatabaseRequest alloc] initWithURLString:url trueOrFalseBlock:^(BOOL success, NSError *error) {
        if (!error) {
            if (success) {
                [[[UIAlertView alloc] initWithTitle:@"Thank you for your feedback!" message:@"Your feedback has been recieved, and we will address any issues as soon as possible." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            }
            else {
                [[[UIAlertView alloc] initWithTitle:@"Unable to send feedback" message:@"There was an error sending your feedback" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            }
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"Unable to send feedback" message:[NSString stringWithFormat:@"There was an error sending your feedback: %@", error.localizedDescription] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        }
    }] startConnection];
}

- (IBAction)cancelSubmission:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

//this is used to set the background image for the button when highlighted
+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size
{
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
