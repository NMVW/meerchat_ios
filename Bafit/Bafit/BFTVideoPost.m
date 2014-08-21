//
//  BFTVideoPost.m
//  Bafit
//
//  Copyright (c) 2014 Bafit. All rights reserved.
//

#import "BFTVideoPost.h"

@implementation BFTVideoPost

-(instancetype)initWithDictionary:(NSDictionary *)jsonDictionary {
    static NSString *baseVideoURL = @"http://bafit.mobi/userPosts";
    static NSString *baseThumbURL = @"http://bafit.mobi/userPosts/thumb";
    
    self = [super init];
    if (self) {
        self.UID = [jsonDictionary objectForKey:@"UID"];
        self.videoURL = [baseVideoURL stringByAppendingPathComponent:[jsonDictionary objectForKey:@"vidURI"]];
        self.thumbURL = [[baseThumbURL stringByAppendingPathComponent:[jsonDictionary objectForKey:@"vidURI"]] stringByAppendingPathExtension:@"jpg"];
        self.MC = [[jsonDictionary objectForKey:@"MC"] integerValue];
        self.category = [[jsonDictionary objectForKey:@"category"] integerValue];
        self.distance = [[jsonDictionary objectForKey:@"dist"] floatValue];
        self.atTag = [jsonDictionary objectForKey:@"at_tag"];
        self.hashTag = [jsonDictionary objectForKey:@"hash_tag"];
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
    return [self.videoURL isEqualToString:[object videoURL]];
}

-(NSString *)description {
    return [NSString stringWithFormat:@"UID: %@\tMC: %zd", self.UID, self.MC];
}

@end
