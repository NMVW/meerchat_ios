//
//  BFTMessageThreads.h
//  Bafit
//
//  Created by Joseph Pecoraro on 9/9/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//
// The purpose of this class is to keep track of all the messages we currently have going on. The backend chose not to handle this currently, so we are handling it here. Essentially, threads stick around locally until you delete them. At some point the majority of this class will be deprecated for a better core data implementation.Also, note that this is a singleton, because it needs to be able to be accessed at any point in time when an xmpp message is recieved. (we could actually put all the xmpp stuff in here...)

#import <Foundation/Foundation.h>

@interface BFTMessageThreads : NSObject

@property (nonatomic, strong) NSMutableOrderedSet *listOfThreads;
@property (nonatomic, assign) BOOL unreadMessages;

+(instancetype)sharedInstance;

-(void)addMessageToThread:(NSString*)message from:(NSString*)sender;
-(void)removeThreadAtIndex:(NSInteger)index;

-(void)saveThreads;
-(void)loadThreadsFromStorage;

-(void)resetUnread;

@end
