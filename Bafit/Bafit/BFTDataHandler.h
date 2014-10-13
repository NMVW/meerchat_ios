//
//  BFTDataHandler.h
//  Bafit
//
//  Created by Keeano Martin on 7/22/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BFTDataHandler : NSObject

+ (BFTDataHandler *)sharedInstance;

@property (nonatomic) BOOL initialLogin;
@property (nonatomic) BOOL PPAccepted;
@property (nonatomic) BOOL emailConfirmed;
@property(nonatomic, retain) NSMutableArray *Username;
@property(nonatomic, copy) NSString *BUN;
@property(nonatomic, copy) NSString *Password;
@property(nonatomic, copy) NSString *EDEmail;
@property(nonatomic, copy) NSString *FBEmail;
@property(nonatomic, copy) NSString *UID;
@property(assign) double Longitude;
@property(assign) double Latitude;
@property(nonatomic, retain) NSArray *numberMessages;
@property (nonatomic, retain) NSMutableArray *images;
@property(assign) BOOL postView;
@property (nonatomic, copy) NSString *mp4Name;
@property (nonatomic, retain) id userInfo;
@property (nonatomic, retain) id FBFriends;

-(void)saveData;
-(void)loadData;

@end
