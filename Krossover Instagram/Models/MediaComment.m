//
//  MediaComment.m
//  Krossover Instagram
//
//  Created by Kevin Li on 7/22/14.
//  Copyright (c) 2014 Kevin Li. All rights reserved.
//

#import "MediaComment.h"

@implementation MediaComment

@synthesize userName, comment;

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self == [super init]) {
        self.userName = [aDecoder decodeObjectForKey:@"userName"];
        self.comment = [aDecoder decodeObjectForKey:@"comment"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.userName forKey:@"userName"];
    [aCoder encodeObject:self.comment forKey:@"comment"];
}

@end
