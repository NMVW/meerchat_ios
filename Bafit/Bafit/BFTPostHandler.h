//
//  BFTPostHandler.h
//  Bafit
//
//  Created by Keeano Martin on 10/8/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BFTPostHandler : NSObject

+(BFTPostHandler *)sharedInstance;

@property (nonatomic,strong) NSString *postUID;
@property (nonatomic,strong) NSString *postAT_Tag;
@property (nonatomic,strong) NSString *postHash_tag;
@property (assign) NSInteger postCategory;
@property (assign) double postGPSLat;
@property (assign) double postGPSLon;
@property (nonatomic,strong) NSString *postFName;
@property (nonatomic,strong) NSString *postMC;
@property (nonatomic, strong) NSString *xmppVideoURL;
@property (nonatomic, strong) NSString *xmppThumbURL;
@property (nonatomic, strong) NSString *xmmpToUser;

@end
