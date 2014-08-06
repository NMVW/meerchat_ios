//
//  BFTLoginhandler.h
//  Bafit
//
//  Created by Keeano Martin on 7/22/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BFTLoginhandler : NSObject

@property(nonatomic) BOOL *isLoggedIn;

+(BOOL)isLoggedIn:(NSString *)username withPassword:(NSString *)password;
+(BOOL)initialLogin;
+(void)setInitialLogin:(BOOL)login;

@end
