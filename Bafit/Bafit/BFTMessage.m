//
//  BFTMessage.m
//  Bafit
//
//  Created by Keeano Martin on 7/29/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTMessage.h"

@implementation BFTMessage

-(id)initWithUsername:(NSString *)username dateTime:(NSString *)time numOfNewMessages:(NSString *)messages
{
    _username = username;
    _dateTime = time;
    _numOfNewMessages = messages;
    return self;
}

@end
