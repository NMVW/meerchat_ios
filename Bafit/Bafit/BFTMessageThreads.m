//
//  BFTMessageThreads.m
//  Bafit
//
//  Created by Joseph Pecoraro on 9/9/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTMessageThreads.h"
#import "BFTBackThreadItem.h"
#import "JSQTextMessage.h"

@implementation BFTMessageThreads

+(instancetype)sharedInstance {
    static BFTMessageThreads *thread = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        thread = [[self alloc] init];
    });
    
    return thread;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        [self loadThreadsFromStorage];
    }
    return self;
}

-(void)addMessageToThread:(NSString *)message from:(NSString *)sender {
    self.unreadMessages = YES;
    
    JSQTextMessage *msg = [[JSQTextMessage alloc] initWithSenderId:sender senderDisplayName:sender date:[NSDate new] text:message];
    
    BFTBackThreadItem *newItem = [[BFTBackThreadItem alloc] init];
    newItem.username = sender;
    
    NSInteger indexOfOldObject = [_listOfThreads indexOfObject:newItem];
    if (indexOfOldObject == NSNotFound) {
        newItem.lastMessageTime = [NSDate new];
        [newItem.listOfMessages addObject:msg];
        [self.listOfThreads addObject:newItem];
    }
    else {
        BFTBackThreadItem *item = [_listOfThreads objectAtIndex:indexOfOldObject];
        item.lastMessageTime = [NSDate new];
        [item.listOfMessages addObject:msg];
    }
}

-(void)removeThreadAtIndex:(NSInteger)index {
    [self.listOfThreads removeObjectAtIndex:index];
}

-(void)loadThreadsFromStorage {
    NSData *data = [NSData dataWithContentsOfFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"messageThreads.archive"]];
    NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    self.listOfThreads = [decoder decodeObjectForKey:@"messageThreads"];
    [decoder finishDecoding];
    
    if (!self.listOfThreads) {
        self.listOfThreads = [[NSMutableOrderedSet alloc] init];
    }
    NSLog(@"Messages Loaded");
}

-(void)saveThreads {
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *coder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [coder encodeObject:self.listOfThreads forKey:@"messageThreads"];
    [coder finishEncoding];
    
    [data writeToFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"messageThreads.archive"] atomically:YES];
    NSLog(@"Messages Saved");
}

-(void)clearThreads {
    self.listOfThreads = [[NSMutableOrderedSet alloc] init];
    [self saveThreads];
}

-(void)resetUnread {
    self.unreadMessages = NO;
}

@end
