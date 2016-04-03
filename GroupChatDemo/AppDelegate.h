//
//  AppDelegate.h
//  GroupChatDemo
//
//  Created by Vaibhav Mistry on 4/3/16.
//  Copyright © 2016 Vaibhav Mistry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) void (^refreshHandler)(void);


@end

