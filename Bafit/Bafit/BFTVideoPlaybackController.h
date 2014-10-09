//
//  BFTVideoPlaybackController.h
//  Bafit
//
//  Created by Joseph Pecoraro on 10/9/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BFTVideoPlaybackController : NSObject

@property (nonatomic, copy) NSURL* videoURL;
@property (nonatomic, copy) NSURL* thumbURL;
@property (nonatomic, strong) UIView *view;

-(instancetype)initWithVideoURL:(NSURL *)videoURL;
-(instancetype)initWithVideoURL:(NSURL *)videoURL andThumbURL:(NSURL *)thumbURL;

-(void)prepareToPlay;
-(void)togglePlayback;
-(void)play;
-(void)stop;
-(void)pause;

@end
