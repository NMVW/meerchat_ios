//
//  BFTForthThreadControllerTableViewController.h
//  Bafit
//
//  Created by Keeano Martin on 8/2/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JSQMessagesViewController/JSQMessages.h>
#import "BFTAppDelegate.h"
#import "BFTMessageDelegate.h"
#import "BFTBackThreadItem.h"

@interface BFTMessageThreadTableViewController : JSQMessagesViewController <BFTMessageDelegate, JSQMessagesInputToolbarDelegate, UITextViewDelegate>

@property (nonatomic, copy) NSString *otherPersonsUserID;
@property (nonatomic, copy) NSString *otherPersonsUserName;

@property (nonatomic, weak) BFTBackThreadItem *messageThread;

@property (nonatomic, assign) NSInteger indexOfLastPlayedVideo;

@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;

@property (nonatomic, weak) BFTAppDelegate *appDelegate;

@end
