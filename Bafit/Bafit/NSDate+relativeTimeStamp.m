//
//  NSDate+relativeTimeStamp.m
//  Bafit
//
//  Created by Joseph Pecoraro on 11/9/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "NSDate+relativeTimeStamp.h"

@implementation NSDate (relativeTimeStamp)

-(NSString*)relativeTimeStamp {
    float numberOfMinutesAgo = [self timeIntervalSinceNow]/-60.0;
    float numberOfHoursAgo = numberOfMinutesAgo/60.0;
    
    if (numberOfMinutesAgo < 60) {
        return [NSString stringWithFormat:@"%.0f minutes ago", numberOfMinutesAgo];
    }
    else {
        return [NSString stringWithFormat:@"%.0f hours ago", numberOfHoursAgo];
    }
}

@end
