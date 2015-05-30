//
//  BFTVideoPlaybackController.m
//  Bafit
//
//  Created by Joseph Pecoraro on 10/9/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTVideoPlaybackController.h"
#import "BFTDatabaseRequest.h"
#import "BFTConstants.h"
#import "SDImageCache.h"
@import AVFoundation;

@implementation BFTVideoPlaybackController {
    BOOL _videoIsPlaying;
    BOOL _shouldPlayWhenReady;
    AVPlayer *_videoPlayer;
    AVPlayerLayer *_playerLayer;
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
    
    [videoThumb setImage:[[SDImageCache sharedImageCache] imageFromDiskCacheForKey:_thumbURL.absoluteString]];
    
    if (!videoThumb.image) {
        [[[BFTDatabaseRequest alloc] initWithFileURL:self.thumbURL.absoluteString completionBlock:^(NSMutableData *data, NSError *error) {
            if (!error) {
                UIImage *image = [UIImage imageWithData:data];
                
                [[SDImageCache sharedImageCache] storeImage:image forKey:_thumbURL.absoluteString];
                [videoThumb setImage:image];
            }
            else {
                //handle image download error
            }
        }] startImageDownload];
    }
    
    _loadingIcon = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [_loadingIcon setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    [self.view addSubview:videoThumb];
    [self.view addSubview:_loadingIcon];
}

-(void)setupVideoPlayer {
    [_loadingIcon startAnimating];
    NSLog(@"setupVideoPlayer");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVPlayerItem *avPlayeritem = [[AVPlayerItem alloc] initWithURL:self.videoURL];
        AVPlayer *avPlayer = [[AVPlayer alloc] initWithPlayerItem:avPlayeritem];
        AVPlayerLayer *avPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:avPlayer];
        [avPlayerLayer setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        
        //UI stuff on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [avPlayerLayer setNeedsLayout];
            [self.view.layer addSublayer:avPlayerLayer];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(seekToBeginning) name:AVPlayerItemDidPlayToEndTimeNotification object:avPlayeritem];
            [avPlayer addObserver:self forKeyPath:@"status" options:0 context:nil];
            [avPlayer addObserver:self forKeyPath:@"rate" options:0 context:nil];
            [avPlayer seekToTime:kCMTimeZero];
            _videoPlayer = avPlayer;
            _playerLayer = avPlayerLayer;
        });
    });
}

#pragma mark - Playback

-(void)prepareToPlay {
    [self setupVideoPlayer];
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
        if (!_videoPlayer) {
            _shouldPlayWhenReady = YES;
            [self setupVideoPlayer];
        }
        else {
            [_videoPlayer play];
            _videoIsPlaying = YES;
        }
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
    _shouldPlayWhenReady = NO;
    _videoIsPlaying = NO;
    if (_playerLayer) {
        [_playerLayer removeFromSuperlayer];
    }
    if (_videoPlayer) {
        [_videoPlayer removeObserver:self forKeyPath:@"status"];
        [_videoPlayer removeObserver:self forKeyPath:@"rate"];
        _videoPlayer = nil;
    }
}

-(void)seekToBeginning {
    _videoIsPlaying = NO;
    _shouldPlayWhenReady = NO;
    [_videoPlayer seekToTime:kCMTimeZero];
    [_videoPlayer pause];
}

#pragma mark - Video Lifecycle and Notifications
     
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (object == _videoPlayer && [keyPath isEqualToString:@"status"]) {
        if (_videoPlayer.status == AVPlayerStatusReadyToPlay) {
            //NSLog(@"Ready To Play");
            if (_shouldPlayWhenReady) {
                [self play];
                _shouldPlayWhenReady = NO;
            }
        } else if (_videoPlayer.status == AVPlayerStatusFailed) {
            //NSLog(@"Stop Animating: Failed");
            //[_loadingIcon stopAnimating];
        }
    }
    else if (object == _videoPlayer && [keyPath isEqualToString:@"rate"]) {
        //NSLog(@"Rate: %.0f", _videoPlayer.rate)
        if (_videoPlayer.rate == 0) {
            [_loadingIcon startAnimating];
        } else if (_videoPlayer.rate == 1) {
            //NSLog(@"Stop Animating: Playback is 1");
            //[_loadingIcon stopAnimating];
        }
    }
}

#pragma mark - Dealloc

-(void)dealloc {
    [self playbackComplete];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _playerLayer = nil;
}

@end
