//
//  BFTVideoMain.h
//  Bafit
//
//  Created by Keeano Martin on 8/6/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface BFTVideoMain : NSObject
@property (retain, nonatomic) AVPlayer *player;

- (id)initWithFrame:(CGRect)frame url:(NSString *)url;

@end
