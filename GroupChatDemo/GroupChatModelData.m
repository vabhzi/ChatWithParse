//
//  GroupChatModelData.m
//  GroupChatDemo
//
//  Created by Vaibhav Mistry on 4/3/16.
//  Copyright © 2016 Vaibhav Mistry. All rights reserved.
//

#import "GroupChatModelData.h"
#import "NSUserDefaults+DemoSettings.h"
#import <Parse.h>


@implementation GroupChatModelData

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        
        if ([NSUserDefaults emptyMessagesSetting])
        {
            self.messages = [NSMutableArray new];
        }
        else
        {
            self.messages = [NSMutableArray new];
        }
        
        JSQMessagesBubbleImageFactory *bubbleFactory =[[JSQMessagesBubbleImageFactory alloc] init];
        
        self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
        self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
    }
    return self;
}



#pragma mark - Loading Data Using Parse

- (void)loadLocalChatwithCompletionHandler:(void (^)(BOOL))completionHandler
{
    
    NSMutableArray *arrTempMsg = [NSMutableArray new];
    __block int totalNumberOfEntries = 0;
    
    
    PFQuery *query = [PFQuery queryWithClassName:@"chatLog"];
    [query orderByAscending:@"createdAt"];
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        
        if (!error)
        {
            /**
             *  The count request succeeded. Log the count
             */
            NSLog(@"There are currently %d entries", number);
            totalNumberOfEntries = number;
            
            NSLog(@"Retrieving data");
            
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects,
                                                      NSError *error) {
                if (!error) {
                    /**
                     *  Success
                     */
                    NSLog(@"Successfully retrieved %lu chats.",
                          (unsigned long)objects.count);
                    [arrTempMsg addObjectsFromArray:objects];
                    [self.messages removeAllObjects];
                    
                    for (int i = 0; i < arrTempMsg.count; i++)
                    {
                        PFObject *obj = arrTempMsg[i];
                        
                        /**
                         *  Checking if downloading message contains an image or not
                         */
                        if ([obj objectForKey:@"image"])
                        {
                            PFFile *file = [obj valueForKey:@"image"];
                            UIImage *image = [UIImage imageNamed:@"loading"];
                            JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:image];
                            JSQMessage *photoMessage = [JSQMessage messageWithSenderId:[obj valueForKey:@"sender"] ?: @"test"
                                                                           displayName:[obj valueForKey:@"sender"] ?: @"test"
                                                                                 media:photoItem];
                            
                            [self.messages addObject:photoMessage];
                            [file getDataInBackgroundWithBlock:^(NSData *data,
                                                                 NSError *error) {
                                if (!error)
                                {
                                    UIImage *image = [UIImage imageWithData:data];
                                    JSQPhotoMediaItem *photoItem =
                                    [[JSQPhotoMediaItem alloc] initWithImage:image];
                                    JSQMessage *photoMessage1 = [JSQMessage messageWithSenderId:[obj valueForKey:@"sender"]
                                                                                    displayName:[obj valueForKey:@"sender"]
                                                                                          media:photoItem];
                                    [self.messages replaceObjectAtIndex:i withObject:photoMessage1];
                                    if (_refreshHandler)
                                    {
                                        _refreshHandler();
                                    }
                                }
                            }];
                        }
                        /**
                         *  Message does not have any image. Only Text
                         */
                        else
                        {
                            NSString *text = [obj valueForKey:@"message"];
                            /**
                             *  Checking if message Message is url an image URL
                             *  Image URL will be rendered as images in the message
                             */
                            if (([text hasPrefix:@"www"] || [text hasPrefix:@"http"] || [text hasPrefix:@"https"]) && ([text hasSuffix:@"png"] || [text hasSuffix:@"jpeg"] ||
                                [text hasSuffix:@"jpg"] || [text hasSuffix:@"gif"])) {
                                UIImage *image = [UIImage imageNamed:@"loading"];
                                JSQPhotoMediaItem *photoItem =
                                [[JSQPhotoMediaItem alloc] initWithImage:image];
                                JSQMessage *photoMessage = [JSQMessage
                                                            messageWithSenderId:[obj valueForKey:@"sender"]
                                                            displayName:[obj valueForKey:@"sender"]
                                                            media:photoItem];
                                
                                [self.messages addObject:photoMessage];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:text]];
                                    UIImage *image = [UIImage imageWithData:data];
                                    JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:image];
                                    JSQMessage *photoMessage1 = [JSQMessage messageWithSenderId:[obj valueForKey:@"sender"]
                                                                                    displayName:[obj valueForKey:@"sender"]
                                                                                          media:photoItem];
                                    [self.messages replaceObjectAtIndex:i withObject:photoMessage1];
                                    if (_refreshHandler)
                                    {
                                        _refreshHandler();
                                    }
                                    
                                });
                            }
                            else
                            {
                                JSQMessage *message = [[JSQMessage alloc]
                                                       initWithSenderId:[obj valueForKey:@"sender"]
                                                       senderDisplayName:[obj valueForKey:@"sender"]
                                                       date:[obj objectForKey:@"date"]
                                                       text:text];
                                [self.messages addObject:message];
                            }
                        }
                    }
                    completionHandler(YES);
                } else {
                    // Log details of the failure
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                }
            }];
            
            
        } else {
            // The request failed, we'll keep the chatData count?
            number = (int)[self.messages count];
        }
    }];
}

#pragma mark - Method to Create and Parse Image Files
- (void)addPhotoMediaMessagewithImage:(UIImage *)image
                withCompletionHandler:(void (^)(BOOL))completionHandler {
    
    /**
     *  Generating message
     */
    NSUserDefaults *standerdDefaults = [NSUserDefaults standardUserDefaults];
    JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:image];
    JSQMessage *photoMessage = [JSQMessage messageWithSenderId:[standerdDefaults valueForKey:@"username"]
                                                   displayName:[standerdDefaults valueForKey:@"username"]
                                                         media:photoItem];
    [self.messages addObject:photoMessage];
    
    /**
     *  Compressing image and saving with name "Image.jpg"
     */
    NSData *data = UIImageJPEGRepresentation(image, 0.5f);
    PFFile *imageFile = [PFFile fileWithName:@"Image.jpg" data:data];
    
    /**
     *  Saving image to Parse
     */
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error)
        {
            NSUserDefaults *standerdDefault = [NSUserDefaults standardUserDefaults];
            PFObject *newPhotoObject = [PFObject objectWithClassName:@"chatLog"];
            [newPhotoObject setObject:imageFile forKey:@"image"];
            [newPhotoObject setObject:[standerdDefault valueForKey:@"username"] forKey:@"sender"];
            [newPhotoObject setObject:[NSDate date] forKey:@"date"];
            
            [newPhotoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                 completionHandler(YES);
                 if (!error)
                 {
                     /**
                      *  Image Saved on Parse
                      */
                     NSLog(@"Saved");
                 }
                 else
                 {
                     /**
                      *  Error
                      */
                     NSLog(@"Error: %@ %@", error, [error userInfo]);
                 }
             }];
        }
    }];
    
    /**
     *  Sending Notification of a mesage through Parse
     */
    NSDictionary *dataDic = @{
                           @"alert" : @"You have received an image!",
                           @"badge" : @"decrement"
                           };
    PFPush *push = [[PFPush alloc] init];
    [push setChannel:@"global"];
    [push setData:dataDic];
    [push sendPushInBackground];
}

@end
