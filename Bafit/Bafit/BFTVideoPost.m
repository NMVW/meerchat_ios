//
//  BFTVideoPost.m
//  Bafit
//
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTVideoPost.h"
#import "BFTConstants.h"

@implementation BFTVideoPost

-(instancetype)initWithDictionary:(NSDictionary *)jsonDictionary {
    static NSString *baseVideoURL = @"http://bafit.mobi/userPosts";
    static NSString *baseThumbURL = @"http://bafit.mobi/userPosts/thumb";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [dateFormatter setTimeZone:gmt];
    
    self = [super init];
    if (self) {
        self.UID = [jsonDictionary objectForKey:@"UID"];
        self.BUN = [jsonDictionary objectForKey:@"BUN"];
        NSString *vidURI = [jsonDictionary objectForKey:@"vidURI"];
        if ([[vidURI pathExtension] isEqualToString:@"mp4"]) {
            self.videoURL = [baseVideoURL stringByAppendingPathComponent:vidURI];
        }
        else {
            self.videoURL = [baseVideoURL stringByAppendingPathComponent:[vidURI stringByAppendingPathExtension:@"mp4"]];
        }
        self.thumbURL = [[baseThumbURL stringByAppendingPathComponent:[jsonDictionary objectForKey:@"vidURI"]] stringByAppendingPathExtension:@"jpg"];
        self.MC = [[jsonDictionary objectForKey:@"MC"] integerValue];
        self.category = [[jsonDictionary objectForKey:@"category"] integerValue];
        self.distance = [[jsonDictionary objectForKey:@"dist"] floatValue];
        self.atTag = [jsonDictionary objectForKey:@"at_tag"];
        self.hashTag = [jsonDictionary objectForKey:@"hash_tag"];
        self.timeStamp = [dateFormatter dateFromString:[jsonDictionary objectForKey:@"TS"]];
        
        self.FBID = [jsonDictionary objectForKey:@"FBID"];
        
        //TODO: Make this pull from database
        self.hasMeerchatConnection = NO;
    }
    return self;
}

-(NSUInteger)hash {
    return [self.videoURL hash];
}

-(BOOL)isEqual:(id)object {
    if (object == self)
        return YES;
    if (!object || ![object isKindOfClass:[self class]])
        return NO;
    return [self.videoURL isEqualToString:[object videoURL]] && [self.timeStamp isEqualToDate:[object timeStamp]] && self.MC == [object MC];
}

-(NSString *)description {
    return [NSString stringWithFormat:@"BUN: %@\tUID: %@\tMC: %zd\nURL: %@", self.BUN, self.UID, self.MC, self.videoURL];
}

@end
