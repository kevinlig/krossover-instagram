//
//  UserResultTableViewCell.h
//  Krossover Instagram
//
//  Created by Kevin Li on 7/24/14.
//  Copyright (c) 2014 Kevin Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserResultTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *profileImage;
@property (nonatomic, weak) IBOutlet UILabel *userNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *realNameLabel;

@end
