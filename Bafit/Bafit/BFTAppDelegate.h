//
//  BFTAppDelegate.h
//  Bafit
//
//  Created by Keeano Martin on 7/18/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import <CoreLocation/CoreLocation.h>
#import "BFTMessageDelegate.h"
#import "XMPP.h"
extern int d;

@interface BFTAppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) CLLocationManager *locationManager;

//xmpp stuff
@property (nonatomic, assign) id<BFTMessageDelegate> messageDelegate;
@property (nonatomic, readonly) XMPPStream *xmppStream;

-(void)registerForNotifications;

-(void)logout;

-(BOOL)connectToJabber;
-(void)setupStream;
-(void)goOnline;
-(void)goOffline;
-(void)sendTextMessage:(NSString*)message toUser:(NSString*)user;
-(void)sendVideoMessageWithURL:(NSString*)videoURL thumbURL:(NSString*)thumbURL toUser:(NSString*)user;


@end
