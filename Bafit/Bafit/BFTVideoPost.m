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
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    
    self = [super init];
    if (self) {
        self.UID = [jsonDictionary objectForKey:@"UID"];
        self.BUN = [jsonDictionary objectForKey:@"BUN"];
        self.videoURL = [baseVideoURL stringByAppendingPathComponent:[jsonDictionary objectForKey:@"vidURI"]];
        self.thumbURL = [[[baseThumbURL stringByAppendingPathComponent:[jsonDictionary objectForKey:@"vidURI"]] stringByDeletingPathExtension] stringByAppendingPathExtension:@"jpg"];
        self.MC = [[jsonDictionary objectForKey:@"MC"] integerValue];
        self.category = [[jsonDictionary objectForKey:@"category"] integerValue];
        self.distance = [[jsonDictionary objectForKey:@"dist"] floatValue];
        self.atTag = [jsonDictionary objectForKey:@"at_tag"];
        self.hashTag = [jsonDictionary objectForKey:@"hash_tag"];
        //TODO:Use date formatter to make this a date object instead of a string;
        self.timeStamp = [dateFormatter dateFromString:[jsonDictionary objectForKey:@"TS"]];
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
