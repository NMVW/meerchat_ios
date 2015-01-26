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
#import "JSQMessage.h"
#import "BFTConstants.h"
#import "BFTDatabaseRequest.h"

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

-(void)addMessageToThread:(NSString *)message from:(NSString *)sender date:(NSDate*)date facebookID:(NSString*)facebookID {
    self.unreadMessages = YES;
    
    JSQMessage *msg = [[JSQMessage alloc] initWithSenderId:sender senderDisplayName:sender date:date text:message];
    
    BFTBackThreadItem *newItem = [[BFTBackThreadItem alloc] init];
    newItem.username = sender;
    
    NSInteger indexOfOldObject = [_listOfThreads indexOfObject:newItem];
    if (indexOfOldObject == NSNotFound) {
        newItem.lastMessageTime = date;
        newItem.facebookID = facebookID;
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
    [self sendMessageToDatabase:[NSString stringWithFormat:@"\%@", message] recipient:reciever];
    JSQMessage *msg = [[JSQMessage alloc] initWithSenderId:[[BFTDataHandler sharedInstance] BUN] senderDisplayName:[[BFTDataHandler sharedInstance] BUN] date:[NSDate new] text:message];
    
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

-(void)addVideoToThreadWithURL:(NSString *)url thumbURL:(NSString *)thumbURL from:(NSString *)sender date:(NSDate*)date facebookID:(NSString*)facebookID {
    self.unreadMessages = YES;
    
    BFTVideoMediaItem *videoItem = [[BFTVideoMediaItem alloc] initWithVideoURL:url thumbURL:thumbURL isOutgoing:NO];
    JSQMessage *msg = [[JSQMessage alloc] initWithSenderId:sender senderDisplayName:sender date:date media:videoItem];
    
    BFTBackThreadItem *newItem = [[BFTBackThreadItem alloc] init];
    newItem.username = sender;
    
    NSInteger indexOfOldObject = [_listOfThreads indexOfObject:newItem];
    if (indexOfOldObject == NSNotFound) {
        newItem.lastMessageTime = date;
        newItem.facebookID = facebookID;
        [newItem.listOfMessages addObject:msg];
        [newItem incrementUnread];
        [newItem setMessagesUnseen:YES];
        [self.listOfThreads addObject:newItem];
    }
    else {
        BFTBackThreadItem *item = [_listOfThreads objectAtIndex:indexOfOldObject];
        item.lastMessageTime = date;
        [item.listOfMessages addObject:msg];
        [item incrementUnread];
        [item setMessagesUnseen:YES];
    }
}

-(void)videoSentWithURL:(NSString *)url thumbURL:(NSString *)thumbURL to:(NSString *)sender {
    [self sendMessageToDatabase:[NSString stringWithFormat:@"Video Message\nvideoURL: %@\nthumbURL: %@", url, thumbURL] recipient:sender];
    BFTVideoMediaItem *videoItem = [[BFTVideoMediaItem alloc] initWithVideoURL:url thumbURL:thumbURL isOutgoing:YES];
    JSQMessage *msg = [[JSQMessage alloc] initWithSenderId:[[BFTDataHandler sharedInstance] BUN] senderDisplayName:[[BFTDataHandler sharedInstance] BUN] date:[NSDate new] media:videoItem];
    
    BFTBackThreadItem *newItem = [[BFTBackThreadItem alloc] init];
    newItem.username = sender;
    
    NSInteger indexOfOldObject = [_listOfThreads indexOfObject:newItem];
    if (indexOfOldObject == NSNotFound) {
        //Since we are sending a video, and there is no thread found, that means that we haven't had a handshake yet
        //They need to send us something back before it opens up a connection for me to start messaging them
        
        /*newItem.lastMessageTime = [NSDate new];
        [newItem.listOfMessages addObject:msg];
        [self.listOfThreads addObject:newItem];*/
    }
    else {
        BFTBackThreadItem *item = [_listOfThreads objectAtIndex:indexOfOldObject];
        item.lastMessageTime = [NSDate new];
        [item.listOfMessages addObject:msg];
        [item incrementUnread];
        [item setMessagesUnseen:YES];
    }
}

-(void)sendMessageToDatabase:(NSString*)body recipient:(NSString*)reciever {
    //send the message to the database
    [[[BFTDatabaseRequest alloc] initWithURLString:[[NSString alloc] initWithFormat:@"sendText.php?UIDr=%@&UIDp=%@&TEXT=%@", [[BFTDataHandler sharedInstance] UID], [reciever lowercaseString], body] trueOrFalseBlock:^(BOOL success, NSError *error) {
        if (!error) {
            if (success) {
                NSLog(@"Messages Succesfully Added to database");
            }
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"Could Not Send Message" message:error.localizedDescription delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        }
    }] startConnection];
}

-(void)removeThreadAtIndex:(NSInteger)index {
    [self.listOfThreads removeObjectAtIndex:index];
}

-(void)loadThreadsFromStorage {
    //TODO: Don't reset the threads. We wont need this anymore pretty soon
    BOOL messagesReset = [[NSUserDefaults standardUserDefaults] boolForKey:@"messagesNeedReset"];
    if (messagesReset) {
        NSData *data = [NSData dataWithContentsOfFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"messageThreads.archive"]];
        NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        self.listOfThreads = [decoder decodeObjectForKey:@"messageThreads"];
        [decoder finishDecoding];
        
        if (!self.listOfThreads) {
            self.listOfThreads = [[NSMutableOrderedSet alloc] init];
        }
        NSLog(@"Messages Loaded");
    }
    else {
        NSLog(@"Messages Have Not Yet Been Reset: Save The Empty Threads");
        [self saveThreads];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"messagesNeedReset"];
    }
}

-(void)saveThreads {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDate *date = [NSDate date];
        NSMutableData *data = [[NSMutableData alloc] init];
        NSKeyedArchiver *coder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [coder encodeObject:self.listOfThreads forKey:@"messageThreads"];
        [coder finishEncoding];
        
        [data writeToFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"messageThreads.archive"] atomically:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Messages Saved in background in %.4f milliseconds", -1*[date timeIntervalSinceNow]*1000);
        });
    });
}

-(void)clearThreads {
    self.listOfThreads = [[NSMutableOrderedSet alloc] init];
    [self saveThreads];
}

-(void)resetUnread {
    self.unreadMessages = NO;
    for (BFTBackThreadItem *thread in self.listOfThreads) {
        [thread clearUnseen];
    }
}

@end
