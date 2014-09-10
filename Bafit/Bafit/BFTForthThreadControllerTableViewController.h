//
//  BFTForthThreadControllerTableViewController.h
//  Bafit
//
//  Created by Keeano Martin on 8/2/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSQMessagesViewController.h"
#import "BFTAppDelegate.h"
#import "BFTMessageDelegate.h"
#import "BFTBackThreadItem.h"

@interface BFTForthThreadControllerTableViewController : JSQMessagesViewController <BFTMessageDelegate>

@property (nonatomic, copy) NSString *otherPersonsUserID;
@property (nonatomic, copy) NSString *otherPersonsUserName;

@property (nonatomic, weak) BFTBackThreadItem *messageThread;

@property (nonatomic, strong) UIImageView *outgoingBubbleImageView;
@property (nonatomic, strong) UIImageView *incomingBubbleImageView;

@property (nonatomic, weak) BFTAppDelegate *appDelegate;

@end
