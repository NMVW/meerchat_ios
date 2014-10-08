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

-(void)dealloc
{
    _videoURL = nil;
}

#pragma mark - JSQMessageMediaData protcol

-(UIView *)mediaView
{
    //TODO:init with either mpmovieplayer or using avfoundation
    return nil;
}

-(CGSize)mediaViewDisplaySize
{
    return CGSizeMake(200.0f, 200.0f);
}

-(UIView *)mediaPlaceholderView
{
    //We dont really need a placeholder. return same view as mediaView?
    //That might not actually work too well though
    return nil;
}

#pragma mark - Video Playback

-(void)beginVideoPlayback {
    NSLog(@"Video Playback Started");
    if (self.canPlayVideo) {
        //TODO: Start playing the mpmovieplayer/avfoundationplayer
    }
    self.canPlayVideo = NO;
}

-(void)endVideoPlayback {
    //TODO:stop the video
    [self videoPlaybackDidFinish];
}

-(void)videoPlaybackDidFinish {
    NSLog(@"Video Stopped Playing");
    self.canPlayVideo = YES;
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
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_videoURL forKey:NSStringFromSelector(@selector(videoURL))];
}

#pragma mark - NSCopying

-(instancetype)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithURL:self.videoURL];
}

@end


