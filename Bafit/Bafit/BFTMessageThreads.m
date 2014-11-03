//
//  BFTMessageThreads.m
//  Bafit
//
//  Created by Joseph Pecoraro on 9/9/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTMessageThreads.h"
#import "BFTBackThreadItem.h"
#import "BFTVideoMediaItem.h"
#import "BFTDataHandler.h"
#import "JSQTextMessage.h"
#import "JSQMediaMessage.h"
#import "BFTConstants.h"

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

-(void)addMessageToThread:(NSString *)message from:(NSString *)sender date:(NSDate*)date {
    self.unreadMessages = YES;
    
    JSQTextMessage *msg = [[JSQTextMessage alloc] initWithSenderId:sender senderDisplayName:sender date:date text:message];
    
    BFTBackThreadItem *newItem = [[BFTBackThreadItem alloc] init];
    newItem.username = sender;
    
    NSInteger indexOfOldObject = [_listOfThreads indexOfObject:newItem];
    if (indexOfOldObject == NSNotFound) {
        newItem.lastMessageTime = date;
        [newItem.listOfMessages addObject:msg];
        [self.listOfThreads addObject:newItem];
    }
    else {
        BFTBackThreadItem *item = [_listOfThreads objectAtIndex:indexOfOldObject];
        item.lastMessageTime = date;
        [item.listOfMessages addObject:msg];
    }
}

-(void)messageSentWithMessage:(NSString *)message to:(NSString *)reciever {
    JSQTextMessage *msg = [[JSQTextMessage alloc] initWithSenderId:[[BFTDataHandler sharedInstance] BUN] senderDisplayName:[[BFTDataHandler sharedInstance] BUN] date:[NSDate new] text:message];
    
    BFTBackThreadItem *newItem = [[BFTBackThreadItem alloc] init];
    newItem.username = reciever;
    
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

-(void)addVideoToThreadWithURL:(NSString *)url thumbURL:(NSString *)thumbURL from:(NSString *)sender date:(NSDate*)date {
    self.unreadMessages = YES;
    
    BFTVideoMediaItem *videoItem = [[BFTVideoMediaItem alloc] initWithVideoURL:url thumbURL:thumbURL];
    JSQMediaMessage *msg = [[JSQMediaMessage alloc] initWithSenderId:sender senderDisplayName:sender date:date media:videoItem];
    
    BFTBackThreadItem *newItem = [[BFTBackThreadItem alloc] init];
    newItem.username = sender;
    
    NSInteger indexOfOldObject = [_listOfThreads indexOfObject:newItem];
    if (indexOfOldObject == NSNotFound) {
        newItem.lastMessageTime = date;
        [newItem.listOfMessages addObject:msg];
        [self.listOfThreads addObject:newItem];
    }
    else {
        BFTBackThreadItem *item = [_listOfThreads objectAtIndex:indexOfOldObject];
        item.lastMessageTime = date;
        [item.listOfMessages addObject:msg];
    }
}

-(void)videoSentWithURL:(NSString *)url thumbURL:(NSString *)thumbURL to:(NSString *)sender {
    BFTVideoMediaItem *videoItem = [[BFTVideoMediaItem alloc] initWithVideoURL:url thumbURL:thumbURL];
    JSQMediaMessage *msg = [[JSQMediaMessage alloc] initWithSenderId:[[BFTDataHandler sharedInstance] BUN] senderDisplayName:[[BFTDataHandler sharedInstance] BUN] date:[NSDate new] media:videoItem];
    
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
    NSDate *date = [NSDate date];
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *coder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [coder encodeObject:self.listOfThreads forKey:@"messageThreads"];
    [coder finishEncoding];
    
    [data writeToFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"messageThreads.archive"] atomically:YES];
    NSLog(@"Messages Saved in %.4f milliseconds", -1*[date timeIntervalSinceNow]*1000);
}

-(void)clearThreads {
    self.listOfThreads = [[NSMutableOrderedSet alloc] init];
    [self saveThreads];
}

-(void)resetUnread {
    self.unreadMessages = NO;
}

@end
