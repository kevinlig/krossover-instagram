//
//  UserProfile.h
//  Krossover Instagram
//
//  Created by Kevin Li on 7/24/14.
//  Copyright (c) 2014 Kevin Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserProfile : NSObject

@property (nonatomic, strong) NSString *instagramId;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *realName;
@property (nonatomic, strong) NSString *photoUrl;

@property int media;
@property int followers;
@property int following;



@property (nonatomic, strong) UIImage *photo;

@end
