//
//  JSQVideoMediaItem.h
//  Bafit
//
//  Created by Joseph Pecoraro on 10/5/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "JSQMessageMediaData.h"

@interface BFTVideoMediaItem : NSObject <JSQMessageMediaData, NSCoding, NSCopying>


@property (strong, nonatomic) NSURL *videoURL;
@property (nonatomic, assign) BOOL canPlayVideo;

-(instancetype)initWithURL:(NSURL*)url;
-(instancetype)initWithURLString:(NSString*)url;

-(void)beginVideoPlayback;
-(void)endVideoPlayback;

-(void)videoPlaybackDidFinish;

@end