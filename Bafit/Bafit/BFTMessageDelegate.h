//
//  BFTMessageDelegate.h
//  Bafit
//
//  Created by Joseph Pecoraro on 9/8/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BFTMessageDelegate <NSObject>

-(void)recievedMessage;

@optional
-(void)friendOnline:(NSString*)buddy;
-(void)friendOffline:(NSString*)buddy;

@end
