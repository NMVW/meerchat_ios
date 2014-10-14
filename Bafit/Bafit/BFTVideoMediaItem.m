//
//  JSQVideoMediaItem.m
//  Bafit
//
//  Created by Joseph Pecoraro on 10/5/14.
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTVideoMediaItem.h"

@implementation BFTVideoMediaItem


#pragma mark - Initialization

-(instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        self.videoURL = url;
    }
    return self;
}

-(instancetype)initWithURLString:(NSString *)url {
    self = [super init];
    if (self) {
        self.videoURL = [NSURL URLWithString:url];
    }
    return self;
}

-(instancetype)initWithVideoURL:(NSString *)url thumbURL:(NSString *)thumbURL {
    self = [super init];
    if (self) {
        self.videoURL = [NSURL URLWithString:url];
        self.thumbURL = [NSURL URLWithString:thumbURL];
    }
    return self;
}

-(void)dealloc
{
    _videoURL = nil;
}

#pragma mark - JSQMessageMediaData protcol

-(UIView *)mediaView
{
    //TODO:init with either mpmovieplayer or using avfoundation
    if (!self.videoView) {
        [self initMovieView];
    }
    return self.videoView.view;
}

-(CGSize)mediaViewDisplaySize
{
    return CGSizeMake(200.0f, 200.0f);
}

-(UIView *)mediaPlaceholderView
{
    if (!self.videoView) {
        [self initMovieView];
    }
    return self.videoView.view;
}

-(void)initMovieView {
    self.videoView = [[BFTVideoPlaybackController alloc] initWithVideoURL:self.videoURL andThumbURL:self.thumbURL];
    [self.videoView.view setFrame:CGRectMake(0, 0, 200, 200)];
}

#pragma mark - Video Playback

-(void)togglePlayback {
    [self.videoView togglePlayback];
}

-(void)beginVideoPlayback {
    [self.videoView play];
}

-(void)endVideoPlayback {
    [self.videoView stop];
}

-(void)pauseVideoPlayback {
    [self.videoView pause];
}

#pragma mark - NSObject

-(BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    BFTVideoMediaItem *videoItem = (BFTVideoMediaItem *)object;
    
    return [self.videoURL isEqual:videoItem.videoURL];
}

-(NSUInteger)hash
{
    return self.videoURL.hash;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@: videourl=%@", [self class], self.videoURL.absoluteString];
}

-(id)debugQuickLookObject
{
    return [self mediaView] ?: [self mediaPlaceholderView];
}

#pragma mark - NSCoding

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _videoURL = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(videoURL))];
        _thumbURL = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(thumbURL))];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_videoURL forKey:NSStringFromSelector(@selector(videoURL))];
    [aCoder encodeObject:_thumbURL forKey:NSStringFromSelector(@selector(thumbURL))];
}

#pragma mark - NSCopying

-(instancetype)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithURL:self.videoURL];
}

@end


