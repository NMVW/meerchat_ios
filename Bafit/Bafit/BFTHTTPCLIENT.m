//
//  BFTHTTPCLIENT.m
//  Bafit
//
//  Created by Keeano Martin on 7/24/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTHTTPCLIENT.h"

@implementation BFTHTTPCLIENT

#pragma mark URLConnectionDelegate Methods

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    __responseData = [[NSMutableData alloc] init];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [__responseData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    
    //Parse Object
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    
}

-(double)newMessages {
    return [_messages count];
}

@end
