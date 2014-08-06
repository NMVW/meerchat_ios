//
//  BFTMessage.h
//  Bafit
//
//  Created by Keeano Martin on 7/29/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BFTMessage : NSObject

@property(nonatomic, copy) NSString *username;
@property(nonatomic, copy) NSString *dateTime;
@property(nonatomic, copy) NSString *numOfNewMessages;


-(id)initWithUsername:(NSString *)username dateTime:(NSString *)time numOfNewMessages:(NSString *)messages;

@end
