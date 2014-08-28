//
//  BFTBackThreadItem.h
//  Bafit
//
//  Created by Joseph Pecoraro on 8/27/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BFTBackThreadItem : NSObject

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *lastMessageTime;
@property (nonatomic, assign) NSInteger numberOfMessages;

@end
