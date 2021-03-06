//
//  BFTForthThreadControllerTableViewController.m
//  Bafit
//
//  Created by Keeano Martin on 8/2/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTMessageThreadTableViewController.h"
#import <JSQMessagesViewController/JSQMessages.h>
#import "BFTDatabaseRequest.h"
#import "BFTDataHandler.h"
#import "BFTVideoMediaItem.h"
#import "BFTVideoMessageViewController.h"
#import "BFTConstants.h"
#import "BFTMessageThreads.h"

@interface BFTMessageThreadTableViewController ()

@end

@implementation BFTMessageThreadTableViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.appDelegate = (BFTAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    self.title = [NSString stringWithFormat:@"@%@", self.otherPersonsUserName];
    self.senderId = [[BFTDataHandler sharedInstance] BUN] ?: @"me";
    
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil]];
    [self.navigationController.navigationBar setBarTintColor:kOrangeColor];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    UIBarButtonItem *exit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(dismissModally)];
    [self.navigationItem setLeftBarButtonItem:exit];
    
    [self loadMessages];
    
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    self.inputToolbar.tintColor = [UIColor colorWithRed: 255/255.0 green:161/255.0 blue:0/255.0 alpha:1.0];
    
    //this is not working for whatever reason
    //UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
    //button.titleLabel.text = @"Record";
    //self.inputToolbar.contentView.leftBarButtonItem = button;
    //self.inputToolbar.contentView.leftBarButtonItemWidth = 60;
    
    JSQMessagesBubbleImageFactory* imageFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    self.outgoingBubbleImageData = [imageFactory outgoingMessagesBubbleImageWithColor:[UIColor whiteColor]];
    self.incomingBubbleImageData = [imageFactory incomingMessagesBubbleImageWithColor:[UIColor whiteColor]];
    
    [self.inputToolbar.contentView.rightBarButtonItem setTintColor:kOrangeColor];
    [self.inputToolbar.contentView.leftBarButtonItem setTintColor:kOrangeColor];
    
    [self.collectionView setBackgroundColor:[UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1]];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.appDelegate.messageDelegate = self;
    [self finishReceivingMessage];
    [self.messageThread clearUnread];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.appDelegate.messageDelegate = nil;
    [self stopPlayingLastVideo];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    NSLog(@"textViewDidBeginEditing");
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    
    if ([[self.messageThread listOfMessages] count] < 2)
    {
        NSLog(@"textViewShouldBeginEditing < 2");
        if (NSClassFromString(@"UIAlertController") != nil) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Please respond with a video" message:@"A video response is required to enable text messaging." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Please record a longer video" message:@"A video response is required to enable text messaging." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        }
        
        return NO;
    }
    else
    {
        return YES;
    }
    
    return YES;
}

-(void)dismissModally {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - JSQMessagesViewController

-(void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date {
    
    //send the message to the xmpp server
    [self.appDelegate sendTextMessage:text toUser:self.otherPersonsUserName];
    
    JSQMessage *prevMessage;
    NSDate *prevDate;
    
    if ([[self.messageThread listOfMessages] count] > 0) {
        prevMessage = [[self.messageThread listOfMessages] lastObject];
        prevDate = prevMessage.date;
    }
    else
    {
        prevDate = date;
    }
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSUInteger unitFlags = NSMinuteCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *components = [gregorian components:unitFlags
                                                fromDate:prevDate
                                                  toDate:date
                                                 options:0];
    NSInteger mins = [components minute];
    
    // add a flag to JSQMessage object for when to show the label. Chronilogical messages must be greater than 10 mins apart to show ts label
    NSString* showTimeLabel;
    if (mins > 10)
    {
        showTimeLabel = @"yes";
    }
    else
    {
        showTimeLabel = @"no";
    }
    
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:senderId senderDisplayName:senderDisplayName date:date text:text showTime:showTimeLabel];
    [[self.messageThread listOfMessages] addObject:message];
    
    [self finishSendingMessage];
}

#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [[self.messageThread listOfMessages] objectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  You may return nil here if you do not want bubbles.
     *  In this case, you should set the background color of your collection view cell's textView.
     *
     *  Otherwise, return your previously created bubble image data objects.
     */
    
    JSQMessage *message = [[self.messageThread listOfMessages] objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outgoingBubbleImageData;
    }
    
    return self.incomingBubbleImageData;
}

- (UIImageView *)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageViewForItemAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    
    JSQMessage *message = [[self.messageThread listOfMessages] objectAtIndex:indexPath.item];
    
    //show time stamp label flag -- only id previous message is greater than 10 mins older
    if ([message.showTime isEqualToString:@"yes"])
    {
        JSQMessage *message = [[self.messageThread listOfMessages] objectAtIndex:indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    
    //if ([[self.messageThread listOfMessages] count] == 1)
    
    if (indexPath.row == 0)
    {
        JSQMessage *message = [[self.messageThread listOfMessages] objectAtIndex:indexPath.item];
        message.showTime = @"yes";
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [[self.messageThread listOfMessages] objectAtIndex:indexPath.item];
    
    //no name if its me
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [[self.messageThread listOfMessages] objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }

    //return message.senderId ? [[NSAttributedString alloc] initWithString:message.senderId] : nil;
    return nil;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[self.messageThread listOfMessages] count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    cell.textView.font = [UIFont systemFontOfSize:17];
    cell.textView.textColor = [UIColor lightGrayColor];
    cell.textView.tintColor = [UIColor colorWithRed: 255/255.0 green:161/255.0 blue:0/255.0 alpha:1.0];
    
    //cell.messageBubbleTopLabel.text = @"";
    
    cell.backgroundColor = kGrayBackground;
    
    return cell;
}

#pragma mark - CollectionView Delegate

-(void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath {
    id<JSQMessageData> messageItem = [collectionView.dataSource collectionView:collectionView messageDataForItemAtIndexPath:indexPath];
    
    if (messageItem.isMediaMessage) {
        if (!(self.indexOfLastPlayedVideo == indexPath.row)) {
            [self pauseLastVideo];
        }
        BFTVideoMediaItem *mediaItem = (BFTVideoMediaItem*)[messageItem media];
        [mediaItem togglePlayback];
        self.indexOfLastPlayedVideo = indexPath.row;
    }
}

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    //timestamp cell height
    JSQMessage *message = [[self.messageThread listOfMessages] objectAtIndex:indexPath.item];
    
    if ([message.showTime isEqualToString:@"yes"]) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    else
    {
        return 0.0f;
    }
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
    
    /*
    //no label for sender
    JSQMessage *currentMessage = [[self.messageThread listOfMessages] objectAtIndex:indexPath.item];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [[self.messageThread listOfMessages] objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
    */
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    return 0.0f;
}

#pragma mark - Toolbar Delegate

-(void)messagesInputToolbar:(JSQMessagesInputToolbar *)toolbar didPressLeftBarButton:(UIButton *)sender {
    [self performSegueWithIdentifier:@"messagesToVideoMessage" sender:self];
}

/*
- (void)messagesInputToolbar:(JSQMessagesInputToolbar *)toolbar didPressRightBarButton:(UIButton *)sender {
}
*/

#pragma mark - Message Delegate

-(void)recievedMessage {
    [self.messageThread clearUnseen];
    [self.messageThread clearUnread];
    [self finishReceivingMessage];
}

#pragma mark - Video Playback

-(void)stopPlayingLastVideo {
    id<JSQMessageData> messageItem = [self.collectionView.dataSource collectionView:self.collectionView messageDataForItemAtIndexPath:[NSIndexPath indexPathForItem:self.indexOfLastPlayedVideo inSection:0]];
    
    if (messageItem.isMediaMessage) {
        BFTVideoMediaItem *mediaItem = (BFTVideoMediaItem*)[messageItem media];
        [mediaItem endVideoPlayback];
    }
}

-(void)pauseLastVideo {
    id<JSQMessageData> messageItem = [self.collectionView.dataSource collectionView:self.collectionView messageDataForItemAtIndexPath:[NSIndexPath indexPathForItem:self.indexOfLastPlayedVideo inSection:0]];
    
    if (messageItem.isMediaMessage) {
        BFTVideoMediaItem *mediaItem = (BFTVideoMediaItem*)[messageItem media];
        [mediaItem pauseVideoPlayback];
    }
}

-(void)loadMessages {
    
    //currently not actually getting messages from the database, plust the message thread class handles this
    /*
    [[[BFTDatabaseRequest alloc] initWithURLString:[NSString stringWithFormat:@"getText.php?UIDr=%@&UIDp=%@&&GPSlat=%.4f&GPSlon=%.4f", [[BFTDataHandler sharedInstance] UID], self.otherPersonsUserID, [[BFTDataHandler sharedInstance] Latitude], [[BFTDataHandler sharedInstance] Longitude]] completionBlock:^(NSMutableData *data, NSError *error){
        if (!error) {
            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
            if (!self.messages) {
                self.messages = [[NSMutableArray alloc] initWithCapacity:[jsonArray count]];
            }
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"yyyy-mm-dd hh:mm:ss";
            for (NSDictionary *dict in jsonArray) {
                JSQMessage *message = [[JSQMessage alloc] initWithText:[dict objectForKey:@"MTEXT"] sender:self.otherPersonsUserName date:[dateFormatter dateFromString:[dict objectForKey:@"TS"]]];
                [self.messages addObject:message];
            }
            
            //we should not have to pull all of these each time..
            [self.collectionView reloadData];
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"Connection Error" message:error.localizedDescription delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        }
    }] startConnection];
     */
}

-(void)record:(id)sender {
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"messagesToVideoMessage"]) {
        BFTVideoMessageViewController *destinationVC = (BFTVideoMessageViewController*)[segue destinationViewController];
        destinationVC.otherPersonsUserName = self.otherPersonsUserName;
        destinationVC.otherPersonsUserID = self.otherPersonsUserID;
    }
}

@end
