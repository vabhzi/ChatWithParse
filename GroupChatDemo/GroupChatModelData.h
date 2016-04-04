//
//  GroupChatModelData.h
//  GroupChatDemo
//
//  Created by Vaibhav Mistry on 4/3/16.
//  Copyright © 2016 Vaibhav Mistry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "JSQMessages.h"


@interface GroupChatModelData : NSObject

@property (strong, nonatomic) NSMutableArray *messages;

@property (strong, nonatomic) NSDictionary *avatars;

@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;

@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;

@property (strong, nonatomic) NSDictionary *users;

@property (strong, nonatomic) void (^refreshHandler) (void);

- (void)addPhotoMediaMessagewithImage:(UIImage *)image
                withCompletionHandler:(void (^)(BOOL))completionHandler;


- (void)loadLocalChatwithCompletionHandler:(void (^)(BOOL))completionHandler;

@end
