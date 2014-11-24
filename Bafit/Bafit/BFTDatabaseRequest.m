//
//  BFTDatabaseConnector.m
//  Bafit
//
//  Created by Joseph Pecoraro on 8/13/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTDatabaseRequest.h"
#import "BFTConstants.h"

@implementation BFTDatabaseRequest

static NSString *kBaseURL = @"http://bafit.mobi/cScripts/v1/";

-(instancetype)initWithURLString:(NSString *)URL completionBlock:(void (^)(NSMutableData *, NSError *))responseHandler {
    self = [super init];
    if (self) {
        _url = [[NSURL alloc] initWithString:[URL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] relativeToURL:[[NSURL alloc] initWithString:kBaseURL]];
        _responseHandler = responseHandler;
        _logMessage = [[NSMutableString alloc] initWithString:@"\n"];
        _timeoutInterval = 10;
    }
    return self;
}

-(instancetype)initWithURLString:(NSString *)URL trueOrFalseBlock:(void (^)(BOOL, NSError *))boolResponseBlock {
    self = [super init];
    if (self) {
        _url = [[NSURL alloc] initWithString:[URL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] relativeToURL:[[NSURL alloc] initWithString:kBaseURL]];
        _boolResponseBlock = boolResponseBlock;
        _logMessage = [[NSMutableString alloc] initWithString:@"\n"];
        _timeoutInterval = 5;
    }
    return self;
}

-(instancetype)initWithFileURL:(NSString *)URL completionBlock:(void (^)(NSMutableData *, NSError *))completionBlock {
    self = [super init];
    if (self) {
        if (!URL)
            return nil;
        _url = [[NSURL alloc] initWithString:[URL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        _responseHandler = completionBlock;
        //_logMessage = [[NSMutableString alloc] initWithString:@"\n"];
        _timeoutInterval = 15;
    }
    return self;
}

-(void)startConnection {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.url];
    [request setHTTPMethod:@"POST"];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setTimeoutInterval:self.timeoutInterval];
    
    [_logMessage appendFormat:@"Connection Began:\nURL:%@", self.url];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

-(void)startSynchronousConnection {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.url];
    [request setHTTPMethod:@"POST"];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setTimeoutInterval:3];
    
    [_logMessage appendFormat:@"Connection Began:\nURL:%@", self.url];
    NSError *error;
    [self connection:_connection didReceiveData:[NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error]];
    [self completeConnection:error];
}

-(void)startImageDownload {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.url];
    [_logMessage appendFormat:@"Connection Began:\nURL:%@", self.url];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

#pragma mark NSURLConnection Delegate

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [_logMessage appendFormat:@"\n\nConnection failed with error: %@\n\n", error.localizedDescription];
    if (error.code == -1005) {
    }
    [self completeConnection:error];
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
        [_logMessage appendFormat:@"\n\nConnection recieved response:\nStatus Code:%zd", httpResponse.statusCode];
    }
    else {
        [_logMessage appendFormat:@"\n\nConnection recieved Response:\n%@", response];
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_logMessage appendFormat:@"\n\nConnection recieved data:\n%@\n\nNumber of KiloBytes: %.4f\n\n", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], [data length]/1024.0];
    if (!_data) {
        _data = [[NSMutableData alloc] init];
    }
    [self.data appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection*) connection {
    [self completeConnection:nil];
}

-(void)completeConnection:(NSError*)error {
    if (self.logMessage) {
        NSLog(@"%@", self.logMessage);
    }
    
    if (_responseHandler) {
        _responseHandler(self.data, error);
    }
    else {
        [self returnBoolValue:error];
    }
    [self destroyConnection];
}

-(void)returnBoolValue:(NSError *)error {
    if (_data) {
        NSString *boolString = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
        _boolResponseBlock([boolString boolValue], error);
    }
    else {
        _boolResponseBlock(NO, error);
    }
}

-(void)destroyConnection {
    [self.connection cancel];
    _connection = nil;
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}


@end
