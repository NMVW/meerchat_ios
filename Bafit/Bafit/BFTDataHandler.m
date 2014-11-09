//
//  BFTDataHandler.m
//  Bafit
//
//  Created by Keeano Martin on 7/22/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTDataHandler.h"
#import "BFTConstants.h"

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
        _postView = false;
        _mp4Name = @"";
        _userInfo = nil;
        _FBFriends = nil;
    }
    return self;
}

+ (BFTDataHandler *)sharedInstance
{
    static BFTDataHandler *_sharedInstance = nil;
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate,^{
            _sharedInstance = [[self alloc] init];
        });
    return _sharedInstance;
}

-(void)setInitialLogin:(BOOL)initialLogin
{
    _initialLogin = initialLogin;
}

-(void)saveData {
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *coder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [coder encodeObject:self.EDEmail forKey:@"EDEmail"];
    [coder encodeObject:self.FBEmail forKey:@"FBEmail"];
    [coder encodeObject:self.UID forKey:@"UID"];
    [coder encodeObject:self.BUN forKey:@"BUN"];
    //[coder encodeObject:self.Password forKey:@"password"];
    [coder encodeFloat:self.Latitude forKey:@"latitude"];
    [coder encodeFloat:self.Longitude forKey:@"longitude"];
    [coder encodeBool:self.emailConfirmed forKey:@"emailConfirmed"];
    [coder encodeBool:self.initialLogin forKey:@"initialLogin"];
    [coder encodeBool:self.PPAccepted forKey:@"ppAccepted"];
    [coder finishEncoding];
    
    [data writeToFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"dataHandler.archive"] atomically:YES];
    NSLog(@"BFTData Saved");
}

-(void)loadData {
    NSData *data = [NSData dataWithContentsOfFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"dataHandler.archive"]];
    NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    self.EDEmail = [decoder decodeObjectForKey:@"EDEmail"];
    self.FBEmail = [decoder decodeObjectForKey:@"FBEmail"];
    self.UID = [decoder decodeObjectForKey:@"UID"];
    self.BUN = [decoder decodeObjectForKey:@"BUN"];
    //self.Password = [decoder decodeObjectForKey:@"password"];
    self.Latitude = [decoder decodeFloatForKey:@"latitude"];
    self.Longitude = [decoder decodeFloatForKey:@"longitude"];
    self.emailConfirmed = [decoder decodeBoolForKey:@"emailConfirmed"];
    self.initialLogin = [decoder decodeBoolForKey:@"initialLogin"];
    self.PPAccepted = [decoder decodeBoolForKey:@"ppAccepted"];
    
    [decoder finishDecoding];
    NSLog(@"BFTData Loaded");
}

@end
