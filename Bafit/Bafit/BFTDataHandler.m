//
//  BFTDataHandler.m
//  Bafit
//
//  Created by Keeano Martin on 7/22/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTDataHandler.h"

@implementation BFTDataHandler

-(id)init
{
    self = [super init];
    if (self) {
     //initlize dataMegan
        _Username = [[NSMutableArray alloc] initWithObjects:@"@JohnB",@"@Mark",@"@Ashley",@"@JohnDoe",@"@Megan",@"@Chelsea",@"@AllenHope",@"@JeffOllen",@"@Trevor",@"@TinkerBell", nil];
        _EDEmail = @"";
        _UID = nil;
        _Password = @"Tester";
        _Longitude = -81.38122;
        _Latitude = 28.54818;
        _initialLogin = true;
        _PPAccepted = false;
        _numberMessages = [[NSArray alloc] initWithObjects:nil];
        _images = [[NSMutableArray alloc] init];
    }
    return self;
}

+ (BFTDataHandler *)sharedInstance
{
    static BFTDataHandler *_sharedInstance = nil;
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate,^
                  {
                      _sharedInstance = [[self alloc] init];
                  });
    return _sharedInstance;
}

-(void)setInitialLogin:(BOOL)initialLogin
{
    _initialLogin = initialLogin;
}

@end
