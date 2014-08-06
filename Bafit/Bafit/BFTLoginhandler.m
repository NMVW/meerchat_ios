//
//  BFTLoginhandler.m
//  Bafit
//
//  Created by Keeano Martin on 7/22/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTLoginhandler.h"
#import "BFTDataHandler.h"

@implementation BFTLoginhandler

+(BOOL)isLoggedIn:(NSString *)username withPassword:(NSString *)password{
    
    if([username isEqualToString:[[BFTDataHandler sharedInstance]Username]] && [password isEqualToString:[[BFTDataHandler sharedInstance]Password]])
    {
        return YES;
    }
    return false;
}

+(BOOL)initialLogin {
    return [[BFTDataHandler sharedInstance]initialLogin];
}
+(void)setInitialLogin:(BOOL)login{
    [[BFTDataHandler sharedInstance] setInitialLogin:login];
}

@end
