//
//  BFTHTTPCLIENT.h
//  Bafit
//
//  Created by Keeano Martin on 7/24/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BFTHTTPCLIENT : NSObject <NSURLConnectionDelegate>

@property (nonatomic, strong)NSMutableData *_responseData;
@property (nonatomic, weak) NSArray *messages;


-(double)newMessages;



@end
