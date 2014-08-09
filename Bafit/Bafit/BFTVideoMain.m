//
//  BFTVideoMain.m
//  Bafit
//
//  Created by Keeano Martin on 8/6/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTVideoMain.h"

@implementation BFTVideoMain

- (id)initWithFrame:(CGRect)frame url:(NSString *)url
{
    self = [super init];
    if (self)
    {
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:url] options:nil];
        //AV Asset Player
        AVPlayerItem * playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
        _player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        playerLayer.frame = frame;
        //        [playerLayer setFrame:_videoView.frame];
        //[_videoView.layer addSublayer:playerLayer];
        [_player seekToTime:kCMTimeZero];
    }
    return self;
}

@end
