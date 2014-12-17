//
//  BFTAppDelegate.m
//  Bafit
//
//  Created by Keeano Martin on 7/18/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTAppDelegate.h"
#import <FacebookSDK/FacebookSDK.h>
#import "BFTMessageThreads.h"
#import "BFTDataHandler.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <Parse/Parse.h>
#import "BFTConstants.h"
#import "SDImageCache.h"


@implementation BFTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Parse setApplicationId:@"wrDBeyyvoetbewUYHqByWOfK1R5PhiTmZiGOJeYO"
                  clientKey:@"09AYDgk4uYTbiFhNdxge5i2HyWQmeOTc85WivX41"];
    [Fabric with:@[CrashlyticsKit]];
    
    //Set navigation color
//    [[UINavigationBar appearance] setTranslucent:NO];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    
    [[BFTDataHandler sharedInstance] loadData];
    
    [self startMonitoringLocation];

    [FBLoginView class];
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    [[SDImageCache sharedImageCache] setMaxCacheSize:20*1024*1024];
    
    UINavigationController *initialViewController;
    
    //make this the default
    initialViewController = [storyboard instantiateViewControllerWithIdentifier:@"loginVC"];
    
    // Whenever a person opens the app, check for a cached session
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        NSError *error = [self openCachedFBSession];
        if (!error) {
            //Since we are here, we know they at least made it to the initial login page
            //if this is true, we need to go to the login page
            if ([[BFTDataHandler sharedInstance] initialLogin]) {
                [initialViewController setViewControllers:@[[storyboard instantiateViewControllerWithIdentifier:@"initialLoginVC"]]];
            }
            else if (![[BFTDataHandler sharedInstance] PPAccepted]) {
                //PP not accepted? go to the pp page
                [initialViewController setViewControllers:@[[storyboard instantiateViewControllerWithIdentifier:@"privacyPolicyVC"]]];
            }
            else if (![[BFTDataHandler sharedInstance] emailConfirmed]) {
                //email not confirmed? confirm email page
                [initialViewController setViewControllers:@[[storyboard instantiateViewControllerWithIdentifier:@"confirmEmailVC"]]];
            }
            else {
                initialViewController = [storyboard instantiateViewControllerWithIdentifier:@"mainVC"];
            }
        }
        else {
            //could not open cached session..
            [initialViewController setViewControllers:@[[storyboard instantiateViewControllerWithIdentifier:@"fbVC"]]];
        }
    }
    else {
        [initialViewController setViewControllers:@[[storyboard instantiateViewControllerWithIdentifier:@"fbVC"]]];
    }
    
    //So we can still get info from people who have registered before fb stuff
    if (![[BFTDataHandler sharedInstance] FBID]) {
        [[FBSession activeSession] closeAndClearTokenInformation];
        [initialViewController setViewControllers:@[[storyboard instantiateViewControllerWithIdentifier:@"fbVC"]]];
    }
    
    self.window.rootViewController = initialViewController;
    [self.window makeKeyAndVisible];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application {
    [self disconnectFromJabber];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[BFTMessageThreads sharedInstance] saveThreads];
    [[BFTDataHandler sharedInstance] saveData];
    [self stopMonitoringLocation];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self startMonitoringLocation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self connectToJabber];
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    [PFInstallation currentInstallation][@"badge"] = @(0);
    [[PFInstallation currentInstallation] saveEventually];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
}

-(void)registerForNotifications {
    NSLog(@"Registering For Push");
    // Register for Push Notitications, if running iOS 8
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                        UIUserNotificationTypeBadge |
                                                        UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                                 categories:nil];
        [[UIApplication sharedApplication]  registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication]  registerForRemoteNotifications];
    } else {
        // Register for Push Notifications before iOS 8
        [[UIApplication sharedApplication]  registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                                                UIRemoteNotificationTypeAlert |
                                                                                UIRemoteNotificationTypeSound)];
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"Push Accepted, save device token");
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation[@"BUN"] = [[[BFTDataHandler sharedInstance] BUN] lowercaseString];
    currentInstallation[@"UID"] = [[BFTDataHandler sharedInstance] UID];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    //[PFPush handlePush:userInfo];
}

#pragma Mark FB Stuff

-(void)logout {
    [[FBSession activeSession] closeAndClearTokenInformation];
    [self goOffline];
}

-(NSError*)openCachedFBSession {
    __block NSError *fbError;
    // If there's one, just open the session silently, without showing the user the login UI
    [FBSession openActiveSessionWithReadPermissions:@[@"public_profile", @"email"] allowLoginUI:NO completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
        fbError = error;
        if (!error) {
            
        }
        else {
            //handle fb login error
        }
    }];
    
    return fbError;
}

#pragma Mark XMPP Messaging Stuff

-(void)setupStream {
    _xmppStream = [[XMPPStream alloc] init];
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSLog(@"Jabber Stream Opened");
}

-(void)goOnline {
    XMPPPresence *presence = [XMPPPresence presence];
    [[self xmppStream] sendElement:presence];
    NSLog(@"Went Online");
}

-(void)goOffline {
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    [[self xmppStream] sendElement:presence];
}

-(BOOL)connectToJabber {
    [[BFTMessageThreads sharedInstance] loadThreadsFromStorage];
    
    //This is to prevent crashing when loading messages based on old data model. I think it actually only effects me.
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"didLoadSinceLibraryUpdate"]) {
        [[BFTMessageThreads sharedInstance] clearThreads];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"didLoadSinceLibraryUpdate"];
    }
    
    [self setupStream];
    
    NSString *jabberID = [NSString stringWithFormat:@"%@@meerchat.mobi", [[BFTDataHandler sharedInstance] BUN]];
    NSString *myPassword = [[BFTDataHandler sharedInstance] BUN];
    
    if (![_xmppStream isDisconnected]) {
        NSLog(@"Connected to Jabber");
        return YES;
    }
    
    if (jabberID == nil || myPassword == nil) {
        NSLog(@"No Jabber Username or Password");
        return NO;
    }
    
    [_xmppStream setMyJID:[XMPPJID jidWithString:jabberID]];
    
    NSError *error = nil;
    if (![_xmppStream connectWithTimeout:10 error:&error]) {
        NSLog(@"Not Logged In: %@", error.localizedDescription);
        return NO;
    }
    
    NSLog(@"Jabber is Logged In");
    return YES;
}

-(void)disconnectFromJabber {
    [self goOffline];
    [self.xmppStream disconnect];
}

-(void)xmppStreamDidConnect:(XMPPStream *)sender {
    NSLog(@"XMPP Stream did connect");

    NSError *error = nil;
    [[self xmppStream] authenticateWithPassword:[[BFTDataHandler sharedInstance] BUN] error:&error];
}

-(void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
    NSLog(@"Authentication successful");
    [self goOnline];
}

//this is called when a buddy goes online/offline, we aren't using this right now
-(void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence {
    NSString *presenceType = [presence type]; // online/offline
    NSString *myUsername = [[sender myJID] user];
    NSString *presenceFromUser = [[presence from] user];
    
    if ([myUsername isEqualToString:presenceFromUser]) {
        return;
    }
    
    if ([presenceType isEqualToString:@"available"]) {
        //[self.messageDelegate friendOnline:presenceFromUser];
    }
    else if ([presenceType isEqualToString:@"unavailable"]) {
        //[self.messageDelegate friendOffline:presenceFromUser];
    }
    
    //NSLog(@"%@ just changed his status to %@", presenceFromUser, presenceType);
}

-(void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
    NSString *type = [[message attributeForName:@"type"] stringValue];
    if ([type isEqualToString:@"chat"]) {
        [self textMessageRecieved:message];
    }
    else if ([type isEqualToString:@"video"]) {
        [self videoMessageRecieved:message];
    }
}

-(void)textMessageRecieved:(XMPPMessage*)message {
    NSString *msg = [[message elementForName:@"body"] stringValue];
    NSString *from = [[message attributeForName:@"from"] stringValue];
    NSString *fromFacebookID = [[message attributeForName:@"facebookID"] stringValue];
    NSString *username = [[from componentsSeparatedByString:@"@meerchat.mobi"] objectAtIndex:0];
    double date = [message attributeDoubleValueForName:@"date"];
    
    if (!msg) {
        return;
    }
    
    [[BFTMessageThreads sharedInstance] addMessageToThread:msg from:username date:[NSDate dateWithTimeIntervalSince1970:date] facebookID:fromFacebookID]; //this makes sure that the message gets delivered if we arent on the messaging screen at the time
    
    [self.messageDelegate recievedMessage]; //notify the current mesage delegate of recieved message
    
    NSLog(@"Message Recieved:\nFrom: %@ID: %@\nMessage:\n%@", username, fromFacebookID, msg);
}

-(void)videoMessageRecieved:(XMPPMessage*)message {
    NSXMLElement *body = [message elementForName:@"body"];
    NSString *videoURL = [[body attributeForName:@"videoURL"] stringValue];
    NSString *thumbURL = [[body attributeForName:@"thumbURL"] stringValue];
    
    NSString *fromFacebookID = [[message attributeForName:@"facebookID"] stringValue];
    NSString *from = [[message attributeForName:@"from"] stringValue];
    NSString *username = [[from componentsSeparatedByString:@"@meerchat.mobi"] objectAtIndex:0];
    double date = [message attributeDoubleValueForName:@"date"];
    
    
    [[BFTMessageThreads sharedInstance] addVideoToThreadWithURL:videoURL thumbURL:thumbURL from:username date:[NSDate dateWithTimeIntervalSince1970:date] facebookID:fromFacebookID];
    
    [self.messageDelegate recievedMessage];
    NSLog(@"Video Message Recieved:\nFrom: %@\nID: %@\nMessage:\n%@", username, fromFacebookID, videoURL);
}

//sends a message through the xmpp stream.
-(void)sendTextMessage:(NSString*)messageBody toUser:(NSString*)user {
    user = [[NSString alloc] initWithFormat:@"%@@meerchat.mobi", user];
    
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:messageBody];
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"facebookID" stringValue:[[BFTDataHandler sharedInstance] FBID]];
    [message addAttributeWithName:@"to" stringValue:user];
    [message addAttributeWithName:@"date" doubleValue:[[NSDate date] timeIntervalSince1970]];
    [message addChild:body];
    
    [self.xmppStream sendElement:message];
    
    NSLog(@"Send Message to User with Body: %@", messageBody);
}

-(void)sendVideoMessageWithURL:(NSString *)videoURL thumbURL:(NSString *)thumbURL toUser:(NSString *)user {
    [[BFTMessageThreads sharedInstance]  videoSentWithURL:videoURL thumbURL:thumbURL to:user];
    user = [[NSString alloc] initWithFormat:@"%@@meerchat.mobi", user];
    
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body addAttributeWithName:@"videoURL" stringValue:videoURL];
    [body addAttributeWithName:@"thumbURL" stringValue:thumbURL];
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"type" stringValue:@"video"];
    [message addAttributeWithName:@"facebookID" stringValue:[[BFTDataHandler sharedInstance] FBID]];
    [message addAttributeWithName:@"to" stringValue:user];
    [message addAttributeWithName:@"date" doubleValue:[[NSDate date] timeIntervalSince1970]];
    [message addChild:body];
    
    [self.xmppStream sendElement:message];
    
    NSLog(@"Send Video Message to User: %@ with URL: %@", user, videoURL);
}

#pragma mark CLLocation Manager

-(void)startMonitoringLocation {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.distanceFilter = 50.0f;
    }
    
    NSInteger authorizationStatus = [CLLocationManager authorizationStatus];

    if (authorizationStatus == (kCLAuthorizationStatusAuthorizedAlways | kCLAuthorizationStatusAuthorized)) {
        //[_locationManager startMonitoringSignificantLocationChanges];
        [_locationManager startUpdatingLocation];
    }
    else if (authorizationStatus == kCLAuthorizationStatusNotDetermined) {
        //Check for ios8, will crash otherwise
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.locationManager requestAlwaysAuthorization];
        }
    }
}

-(void)stopMonitoringLocation {
    //[_locationManager stopMonitoringSignificantLocationChanges];
    [_locationManager startUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *newLocation = [locations firstObject];
    
    NSLog(@"Accuracy: %.0f latitude %+.6f, longitude %+.6f\n", newLocation.horizontalAccuracy,
          newLocation.coordinate.latitude,
          newLocation.coordinate.longitude);
    
    [[BFTDataHandler sharedInstance] setLatitude:newLocation.coordinate.latitude];
    [[BFTDataHandler sharedInstance] setLongitude:newLocation.coordinate.longitude];
}

-(void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
    NSLog(@"Location Manager Did Pause Location Updates");
}

-(void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
    NSLog(@"Location Manager did Resume Location Updates");
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location manager failed with error: %@", error.localizedDescription);
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSLog(@"CLAuthorization Status: %i", status);
    [self startMonitoringLocation];
}

@end
