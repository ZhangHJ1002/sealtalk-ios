//
//  RCDPersonDetailViewController.h
//  SealTalk
//
//  Created by 孙浩 on 2019/5/30.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCDPersonDetailViewController : UIViewController
+ (UIViewController *)configVC:(NSString *)userId groupId:(NSString *)groupId;
@property (nonatomic, strong) NSString *userId;
@end


