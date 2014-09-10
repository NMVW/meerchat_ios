//
//  BFTForthThreadControllerTableViewController.m
//  Bafit
//
//  Created by Keeano Martin on 8/2/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTForthThreadControllerTableViewController.h"
#import "JSQMessage.h"
#import "JSQMessagesBubbleImageFactory.h"
#import "JSQMessagesTimeStampFormatter.h"
#import "JSQMessagesCollectionViewCell.h"
#import "JSQMessagesInputToolbar.h"
#import "JSQMessagesToolbarContentView.h"
#import "BFTDatabaseRequest.h"
#import "BFTDataHandler.h"

@interface BFTForthThreadControllerTableViewController ()

@end

@implementation BFTForthThreadControllerTableViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.appDelegate = (BFTAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    self.title = self.otherPersonsUserName;
    self.sender = [[BFTDataHandler sharedInstance] BUN] ?: @"me";
    
    [self loadMessages];
    
    self.outgoingBubbleImageView = [JSQMessagesBubbleImageFactory outgoingMessageBubbleImageViewWithColor:[UIColor whiteColor]];
    self.incomingBubbleImageView = [JSQMessagesBubbleImageFactory incomingMessageBubbleImageViewWithColor:[UIColor whiteColor]];
    
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    self.inputToolbar.tintColor = [UIColor colorWithRed: 255/255.0 green:161/255.0 blue:0/255.0 alpha:1.0];

    self.inputToolbar.contentView.leftBarButtonItem = nil;
    
    //this is not working for whatever reason
    //UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
    //button.titleLabel.text = @"Record";
    //self.inputToolbar.contentView.leftBarButtonItem = button;
    //self.inputToolbar.contentView.leftBarButtonItemWidth = 60;
    
    [self.inputToolbar.contentView.rightBarButtonItem setTintColor:[UIColor colorWithRed: 255/255.0 green:161/255.0 blue:0/255.0 alpha:1.0]];
    [self.inputToolbar.contentView.leftBarButtonItem setTintColor:[UIColor colorWithRed: 255/255.0 green:161/255.0 blue:0/255.0 alpha:1.0]];
    
    [self.collectionView setBackgroundColor:[UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1]];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.appDelegate.messageDelegate = self;
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.appDelegate.messageDelegate = nil;
}

#pragma mark - JSQMessagesViewController

-(void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text sender:(NSString *)sender date:(NSDate *)date {
    //send the message to the database
    [[[BFTDatabaseRequest alloc] initWithURLString:[[NSString alloc] initWithFormat:@"sendText.php?UIDr=%@&UIDp=%@&TEXT=%@", [[BFTDataHandler sharedInstance] UID], self.otherPersonsUserID, text] trueOrFalseBlock:^(BOOL success, NSError *error) {
        if (!error) {
            if (success) {
                NSLog(@"Messages Succesfully Added to database");
            }
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"Could Not Send Message" message:error.localizedDescription delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        }
    }] startConnection];
    
    //send the message to the xmpp server
    //TODO: Carlo wants us to use the database for messaging, and xmpp just to notify of when we need updates. This could then be modified to notify of something specific
    [self.appDelegate sendMessage:text toUser:self.otherPersonsUserName];
    
    JSQMessage *message = [[JSQMessage alloc] initWithText:text sender:sender date:date];
    [[self.messageThread listOfMessages] addObject:message];
    
    [self finishSendingMessage];
}

#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [[self.messageThread listOfMessages] objectAtIndex:indexPath.item];
}

- (UIImageView *)collectionView:(JSQMessagesCollectionView *)collectionView bubbleImageViewForItemAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessage *message = [[self.messageThread listOfMessages] objectAtIndex:indexPath.item];
    
    if ([message.sender isEqualToString:self.sender]) {
        return [[UIImageView alloc] initWithImage:self.outgoingBubbleImageView.image
                                 highlightedImage:self.outgoingBubbleImageView.highlightedImage];
    }
    
    return [[UIImageView alloc] initWithImage:self.incomingBubbleImageView.image
                             highlightedImage:self.incomingBubbleImageView.highlightedImage];
}

- (UIImageView *)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageViewForItemAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    //show a timestamp for every third message
    if (indexPath.item % 3 == 0) {
        JSQMessage *message = [[self.messageThread listOfMessages] objectAtIndex:indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [[self.messageThread listOfMessages] objectAtIndex:indexPath.item];
    
    //no name if its me
    if ([message.sender isEqualToString:self.sender]) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [[self.messageThread listOfMessages] objectAtIndex:indexPath.item - 1];
        if ([[previousMessage sender] isEqualToString:message.sender]) {
            return nil;
        }
    }

    return [[NSAttributedString alloc] initWithString:message.sender];
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[self.messageThread listOfMessages] count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    cell.textView.textColor = [UIColor lightGrayColor];
    cell.textView.tintColor = [UIColor colorWithRed: 255/255.0 green:161/255.0 blue:0/255.0 alpha:1.0];
    
    return cell;
}

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    //timestamp cell height
    if (indexPath.item % 3 == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    //no label for sender
    JSQMessage *currentMessage = [[self.messageThread listOfMessages] objectAtIndex:indexPath.item];
    if ([[currentMessage sender] isEqualToString:self.sender]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [[self.messageThread listOfMessages] objectAtIndex:indexPath.item - 1];
        if ([[previousMessage sender] isEqualToString:[currentMessage sender]]) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    return 0.0f;
}

#pragma mark Message Delegate

-(void)recievedMessage:(NSString *)message fromSender:(NSString *)sender {
    //this should already be handled in the BFTMessages class
    //Note: TODO: Carlo wants us to actually pull the messages here, but Since I'm already getting the message from xmpp, I'm not going to at this time.
    
    [self finishReceivingMessage];
}

#pragma mark Other

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

@end
