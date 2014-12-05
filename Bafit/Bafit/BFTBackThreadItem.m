//
//  BFTBackThreadItem.m
//  Bafit
//
//  Created by Joseph Pecoraro on 8/27/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTBackThreadItem.h"

@implementation BFTBackThreadItem

-(instancetype)init {
    self = [super init];
    if (self) {
        _listOfMessages = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark NSCoding

//This will be replaced with a core data implementation at some point
-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.username = [aDecoder decodeObjectForKey:@"username"];
        self.userID = [aDecoder decodeObjectForKey:@"userID"];
        self.facebookID = [aDecoder decodeObjectForKey:@"facebookID"];
        self.lastMessageTime = [aDecoder decodeObjectForKey:@"mostRecentMessage"];
        self.listOfMessages = [aDecoder decodeObjectForKey:@"messages"];
        
        self.numberUnreadMessages = [aDecoder decodeIntegerForKey:@"numUnread"];
        self.messagesUnseen = [aDecoder decodeBoolForKey:@"unSeen"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.username forKey:@"username"];
    [aCoder encodeObject:self.userID forKey:@"userID"];
    [aCoder encodeObject:self.facebookID forKey:@"facebookID"];
    [aCoder encodeObject:self.lastMessageTime forKey:@"mostRecentMessage"];
    [aCoder encodeObject:self.listOfMessages forKey:@"messages"];
    
    [aCoder encodeInteger:self.numberUnreadMessages forKey:@"numUnread"];
    [aCoder encodeBool:self.messagesUnseen forKey:@"unSeen"];
}

-(void)incrementUnread {
    self.numberUnreadMessages++;
}

-(void)clearUnread {
    self.numberUnreadMessages = 0;
}

-(void)clearUnseen {
    self.messagesUnseen = NO;
}

-(NSUInteger)hash {
    return [self.username hash];
}

-(BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[BFTBackThreadItem class]]) {
        if (![object lastMessageTime]) {
            return [self.username isEqualToString:[object username]];
        }
        else {
            return [self.username isEqualToString:[object username]] && [self.lastMessageTime isEqual:[object lastMessageTime]];
        }
    }
    return NO;
}

@end
