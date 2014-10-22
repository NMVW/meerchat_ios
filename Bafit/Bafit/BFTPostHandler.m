//
//  BFTPostHandler.m
//  Bafit
//
//  Created by Keeano Martin on 10/8/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTPostHandler.h"

@implementation BFTPostHandler

-(id)init
{
    self = [super init];
    if(self){
        _postUID = @"";
        _postAT_Tag = @"";
        _postHash_tag = @"";
        _postCategory = 0;
        _postGPSLat = 28.54818;
        _postGPSLon = -81.38122;
        _postFName = @"";
        _postMC = @"";
        _xmmpToUser = @"";
        _xmppThumbURL = @"";
        _xmppVideoURL = @"";
    }
    return self;
}

+ (BFTPostHandler *)sharedInstance {
    static BFTPostHandler *_sharedInstance = nil;
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate,^{
        _sharedInstance = [[self alloc]init];
    });
    return _sharedInstance;
}

@end
