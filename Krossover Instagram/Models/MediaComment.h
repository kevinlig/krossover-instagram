//
//  MediaComment.h
//  Krossover Instagram
//
//  Created by Kevin Li on 7/22/14.
//  Copyright (c) 2014 Kevin Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MediaComment : NSObject <NSCoding>

@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *comment;

@end
