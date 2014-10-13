//
//  BFTVideoPlaybackController.m
//  Bafit
//
//  Created by Joseph Pecoraro on 10/9/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTVideoPlaybackController.h"
#import "BFTDatabaseRequest.h"
@import AVFoundation;

@implementation BFTVideoPlaybackController {
    BOOL _videoIsPlaying;
    AVPlayer *_videoPlayer;
}

-(instancetype)initWithVideoURL:(NSURL *)contentURL {
    self = [super init];
    if (self) {
        self.videoURL = contentURL;
        [self initViewWithFrame:CGRectMake(0, 0, 200, 200)];
    }
    return self;
}

-(instancetype)initWithVideoURL:(NSURL *)contentURL andThumbURL:(NSURL *)thumbURL {
    self = [super init];
    if (self) {
        self.videoURL = contentURL;
        self.thumbURL = thumbURL;
        [self initViewWithFrame:CGRectMake(0, 0, 200, 200)];
    }
    return self;
}

-(instancetype)initWithVideoURL:(NSURL *)contentURL andThumbURL:(NSURL *)thumbURL frame:(CGRect)frame {
    self = [super init];
    if (self) {
        self.videoURL = contentURL;
        self.thumbURL = thumbURL;
        [self initViewWithFrame:frame];
    }
    return self;
}

#pragma mark - View

-(void)initViewWithFrame:(CGRect)frame {
    self.view = [[UIView alloc] initWithFrame:frame];
    
    //Thumbnail
    UIImageView *videoThumb = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    videoThumb.backgroundColor = [UIColor colorWithRed:123/255.0 green:123/255.0 blue:123/255.0 alpha:1.0];
    [videoThumb setContentMode:UIViewContentModeScaleAspectFit];
    
    //TODO:Look into cache first
    //[videoThumb setImage:Cache objectForKey:[[_videoPosts objectAtIndex:index] thumbURL]]];
    
    if (!videoThumb.image) {
        [[[BFTDatabaseRequest alloc] initWithFileURL:self.thumbURL.absoluteString completionBlock:^(NSMutableData *data, NSError *error) {
            if (!error) {
                UIImage *image = [UIImage imageWithData:data];
                
                //TODO:Cache the image
                //[_tempImageCache setObject:image forKey:[[_videoPosts objectAtIndex:index] thumbURL]];
                [videoThumb setImage:image];
            }
            else {
                //handle image download error
            }
        }] startImageDownload];
    }
    
    [self.view addSubview:videoThumb];
}

-(void)setupVideoPlayer {
    AVPlayerItem *avPlayeritem = [[AVPlayerItem alloc] initWithURL:self.videoURL];
    AVPlayer *avPlayer = [[AVPlayer alloc] initWithPlayerItem:avPlayeritem];
    AVPlayerLayer *avPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:avPlayer];
    [avPlayerLayer setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [avPlayerLayer setNeedsLayout];
    [self.view.layer addSublayer:avPlayerLayer];
    
    //Assign to notication to check for end of playback
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackComplete) name:AVPlayerItemDidPlayToEndTimeNotification object:avPlayeritem];
    [avPlayer seekToTime:kCMTimeZero];
    [avPlayer play];
    _videoPlayer = avPlayer;
}

#pragma mark - Playback

-(void)prepareToPlay {
    
}

-(void)togglePlayback {
    if (_videoIsPlaying) {
        [self pause];
    }
    else {
        [self play];
    }
}

-(void)play {
    if (!_videoIsPlaying) {
        if (_videoPlayer) {
            [_videoPlayer play];
        }
        else {
            [self setupVideoPlayer];
        }
        _videoIsPlaying = YES;
    }
}

-(void)stop {
    if (_videoIsPlaying) {
        [self pause];
    }
    [self playbackComplete];
}

-(void)pause {
    [_videoPlayer pause];
    _videoIsPlaying = NO;
}

-(void)playbackComplete {
    _videoPlayer = nil;
}

@end
