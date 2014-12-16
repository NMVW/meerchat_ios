//
//  BFTVideoPost.h
//  Bafit
//
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BFTVideoPost : NSObject

@property (nonatomic, copy) NSString *UID;
@property (nonatomic, copy) NSString *BUN;
@property (nonatomic, copy) NSString *videoURL;
@property (nonatomic, copy) NSString *thumbURL;
@property (nonatomic, assign) NSInteger MC;

@property (nonatomic, assign) NSInteger category;
@property (nonatomic, assign) float distance;
@property (nonatomic, strong) NSDate *timeStamp;
@property (nonatomic, copy) NSString *atTag;
@property (nonatomic, copy) NSString *hashTag;

@property (nonatomic, assign) BOOL isFacebookFriend;
@property (nonatomic, assign) BOOL hasMeerchatConnection;

-(instancetype)initWithDictionary:(NSDictionary *)jsonDictionary;

@end
