//
//  Message.h
//  GroupChatDemo
//
//  Created by Vaibhav Mistry on 4/3/16.
//  Copyright © 2016 Vaibhav Mistry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Message : NSObject

@property (nonatomic, strong) NSString *text, *senderName, *mediaId;

@end
