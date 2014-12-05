//
//  BFTBackThreadItem.h
//  Bafit
//
//  Created by Joseph Pecoraro on 8/27/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BFTBackThreadItem : NSObject <NSCoding>

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *facebookID;
@property (nonatomic, strong) NSDate *lastMessageTime;

@property (nonatomic, strong) NSMutableArray *listOfMessages;

@property (nonatomic, assign) NSInteger numberUnreadMessages;
@property (nonatomic, assign) BOOL messagesUnseen;

-(void)clearUnread;
-(void)clearUnseen;
-(void)incrementUnread;

@end
