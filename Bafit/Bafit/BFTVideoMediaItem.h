//
//  JSQVideoMediaItem.h
//  Bafit
//
//  Created by Joseph Pecoraro on 10/5/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "JSQMessageMediaData.h"
#import "BFTVideoPlaybackController.h"

@interface BFTVideoMediaItem : NSObject <JSQMessageMediaData, NSCoding, NSCopying>


@property (strong, nonatomic) NSURL *videoURL;
@property (strong, nonatomic) NSURL *thumbURL;

@property (nonatomic, strong) BFTVideoPlaybackController* videoView;

-(instancetype)initWithURL:(NSURL*)url;
-(instancetype)initWithURLString:(NSString*)url;
-(instancetype)initWithVideoURL:(NSString*)url thumbURL:(NSString*)thumbURL;

-(void)togglePlayback;
-(void)beginVideoPlayback;
-(void)endVideoPlayback;
-(void)pauseVideoPlayback;

@end