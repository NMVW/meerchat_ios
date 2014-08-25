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

@interface BFTFeedbackViewController () <UIPickerViewDataSource, UIPickerViewDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *issuesExperiencedLabel;
@property (weak, nonatomic) IBOutlet UIPickerView *issuesPickerView;
@property (weak, nonatomic) IBOutlet UITextView *issuesDetailTextView;
@property (weak, nonatomic) IBOutlet UITextView *commentsFeedbackTextView;
@property (weak, nonatomic) IBOutlet UILabel *issuesLabel;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (weak, nonatomic) IBOutlet UISwitch *recommendSwitch;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@end

@implementation BFTFeedbackViewController {
    BOOL _datePickerShowing;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.issuesExperiencedLabel setFont:[UIFont boldSystemFontOfSize:16]];
    
    UIColor *orangeButtonBorder = [UIColor colorWithRed:240/255.0f green:162/255.0f blue:44/255.0f alpha:1];
    self.submitButton.layer.cornerRadius = 5.0f;
    self.submitButton.layer.borderWidth = 2.0f;
    self.submitButton.layer.borderColor = orangeButtonBorder.CGColor;
    self.submitButton.clipsToBounds = YES;
    [self.submitButton setBackgroundImage:[BFTFeedbackViewController imageWithColor:orangeButtonBorder size:self.submitButton.frame.size] forState:UIControlStateHighlighted];
    [self.submitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    
    self.cancelButton.layer.cornerRadius = 5.0f;
    self.cancelButton.layer.borderWidth = 2.0f;
    self.cancelButton.layer.borderColor = orangeButtonBorder.CGColor;
    self.cancelButton.clipsToBounds = YES;
    [self.cancelButton setBackgroundImage:[BFTFeedbackViewController imageWithColor:orangeButtonBorder size:self.cancelButton.frame.size] forState:UIControlStateHighlighted];
    [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
}

#pragma mark Table View

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return (section == 0 || section == 2) ? 35 : 0.01f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return section == 3 ? 60 : 0.01f;
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

- (IBAction)submitForm:(id)sender {
    BFTDataHandler *handler = [BFTDataHandler sharedInstance];
    
    NSString *url = [[NSString alloc] initWithFormat:@"sendFeedback.php?UID=%@&BUN=%@&issue=%@&issueDetail=%@&contFeedback=%@&recommend=%@&GPSlat=%.4fGPSlon=%.4f", [handler UID], [handler BUN], self.issuesLabel.text, self.issuesDetailTextView.text, self.commentsFeedbackTextView.text, [NSNumber numberWithBool:[self.recommendSwitch isOn]], [handler Latitude], [handler Longitude]];
    
    NSLog(@"Submit Feedback Script: %@", url);
    /*[[[BFTDatabaseRequest alloc] initWithURLString:url trueOrFalseBlock:^(BOOL success, NSError *error) {
        if (!error) {
            
        }
        else {
            //handle connection error
        }
    }] startConnection];*/
    
    //send form email
    [self dismissViewControllerAnimated:YES completion:nil];
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
