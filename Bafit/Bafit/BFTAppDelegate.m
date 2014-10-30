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
#import <Crashlytics/Crashlytics.h>
#import "BFTConstants.h"
#import "Flurry.h"


@implementation BFTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //Flurry Authentication
    [Flurry setCrashReportingEnabled:YES];
    
    // Replace YOUR_API_KEY with the api key in the downloaded package
    [Flurry startSession:@"H87STTM6HJF6CQC8Y49S"];
    [Crashlytics startWithAPIKey:@"79408de8296f5247d8a98cf57977f3ddc206c935"];
    
    //Set navigation color
//    [[UINavigationBar appearance] setTranslucent:NO];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:255.0f/255.0f green:161.0f/255.0f blue:0.0f/255.0f alpha:1.0]];
    
    [[BFTDataHandler sharedInstance] loadData];
    
    // Override point for customization after application launch.
    //BFTDataHandler *handler = [[BFTDataHandler alloc]init];
    if(self.locationManager == nil){
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.distanceFilter = 500;
        self.locationManager = _locationManager;
    }
    
    if([CLLocationManager locationServicesEnabled]){
        [_locationManager startUpdatingLocation];
    }

    [FBLoginView class];
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
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
    
    self.window.rootViewController = initialViewController;
    [self.window makeKeyAndVisible];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    [self disconnectFromJabber];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[BFTMessageThreads sharedInstance] saveThreads];
    [[BFTDataHandler sharedInstance] saveData];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self connectToJabber];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
}

#pragma Mark FB Stuff

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
    NSString *username = [[from componentsSeparatedByString:@"@meerchat.mobi"] objectAtIndex:0];
    
    if (!msg) {
        return;
    }
    
    [[BFTMessageThreads sharedInstance] addMessageToThread:msg from:username]; //this makes sure that the message gets delivered if we arent on the messaging screen at the time
    
    [self.messageDelegate recievedMessage]; //notify the current mesage delegate of recieved message
    
    NSLog(@"Message Recieved:\nFrom: %@\nMessage:\n%@", from, msg);
}

-(void)videoMessageRecieved:(XMPPMessage*)message {
    NSXMLElement *body = [message elementForName:@"body"];
    NSString *videoURL = [[body attributeForName:@"videoURL"] stringValue];
    NSString *thumbURL = [[body attributeForName:@"thumbURL"] stringValue];
    
    NSString *from = [[message attributeForName:@"from"] stringValue];
    NSString *username = [[from componentsSeparatedByString:@"@meerchat.mobi"] objectAtIndex:0];
    
    [[BFTMessageThreads sharedInstance] addVideoToThreadWithURL:videoURL thumbURL:thumbURL from:username];
    
    [self.messageDelegate recievedMessage];
    NSLog(@"Video Message Recieved:\nFrom: %@\nMessage:\n%@", username, videoURL);
}

//sends a message through the xmpp stream.
-(void)sendTextMessage:(NSString*)messageBody toUser:(NSString*)user {
    user = [[NSString alloc] initWithFormat:@"%@@meerchat.mobi", user];
    
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:messageBody];
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"to" stringValue:user];
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
    [message addAttributeWithName:@"to" stringValue:user];
    [message addChild:body];
    
    [self.xmppStream sendElement:message];
    
    NSLog(@"Send Video Message to User: %@ with URL: %@", user, videoURL);
}

#pragma mark CLLocation Manager

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    
    NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) <= 15.0)
    {
        //Location timestamp is within the last 15.0 seconds, let's use it!
        if(newLocation.horizontalAccuracy <= 35.0){
            //Location seems pretty accurate, let's use it!
            NSLog(@"latitude %+.6f, longitude %+.6f\n",
                  newLocation.coordinate.latitude,
                  newLocation.coordinate.longitude);
            NSLog(@"Horizontal Accuracy:%f", newLocation.horizontalAccuracy);
            
            [[BFTDataHandler sharedInstance] setLatitude:newLocation.coordinate.latitude];
            [[BFTDataHandler sharedInstance] setLongitude:newLocation.coordinate.longitude];
            
            //Optional: turn off location services once we've gotten a good location
            [manager stopUpdatingLocation];
        }
    }
    
}

@end
