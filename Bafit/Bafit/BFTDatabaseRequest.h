//
//  BFTDatabaseConnector.h
//  Bafit
//
//  Created by Joseph Pecoraro on 8/13/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BFTDatabaseRequest : NSObject <NSURLConnectionDelegate>

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSURLConnection *connection;
@property (copy) void(^responseHandler)(NSMutableData* data, NSError* error);
@property (copy) void(^boolResponseBlock)(BOOL);

@property (nonatomic, assign) NSInteger timeoutInterval;

@property (nonatomic, strong) NSMutableString *logMessage;

//Use this if you want to decode a json response
-(instancetype)initWithURLString:(NSString *)URL completionBlock:(void (^)(NSMutableData *, NSError *))responseHandler;
//Use this if you just want YES or NO back
-(instancetype)initWithURLString:(NSString *)URL trueOrFalseBlock:(void (^)(BOOL))boolResponseBlock;

//must call this to send request
-(void)startConnection;
-(void)startSynchronousConnection;

@end
