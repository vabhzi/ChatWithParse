//
//  Message.m
//  GroupChatDemo
//
//  Created by Vaibhav Mistry on 4/3/16.
//  Copyright © 2016 Vaibhav Mistry. All rights reserved.
//

#import "Message.h"

@implementation Message




-(instancetype) initMessageWith:(NSString *)text sender:(NSString *)senderName media:(NSString *)mediaId
{
    self = [super init];
    _text = text;
    _senderName = senderName;
    _mediaId = mediaId;
    return self;
}

@end
