//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSQMessagesViewController
//
//
//  GitHub
//  https://github.com/jessesquires/JSQMessagesViewController
//
//
//  License
//  Copyright (c) 2014 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

#import "DemoModelData.h"

#import "NSUserDefaults+DemoSettings.h"
#import <Parse.h>

#define MAX_ENTRIES_LOADED 25

/**
 *  This is for demo/testing purposes only.
 *  This object sets up some fake model data.
 *  Do not actually do anything like this.
 */

@implementation DemoModelData

- (instancetype)init {
  self = [super init];
  if (self) {

    if ([NSUserDefaults emptyMessagesSetting]) {
      self.messages = [NSMutableArray new];
    } else {
      self.messages = [NSMutableArray new];
    }

    /**
     *  Create message bubble images objects.
     *
     *  Be sure to create your bubble images one time and reuse them for good
     * performance.
     *
     */
    JSQMessagesBubbleImageFactory *bubbleFactory =
        [[JSQMessagesBubbleImageFactory alloc] init];

    self.outgoingBubbleImageData =
        [bubbleFactory outgoingMessagesBubbleImageWithColor:
                           [UIColor jsq_messageBubbleLightGrayColor]];
    self.incomingBubbleImageData = [bubbleFactory
        incomingMessagesBubbleImageWithColor:[UIColor
                                                 jsq_messageBubbleGreenColor]];
  }

  return self;
}

#pragma mark - Parse

- (void)loadLocalChatwithCompletionHandler:(void (^)(BOOL))completionHandler {
  NSMutableArray *arrTempMsg = [NSMutableArray new];
  PFQuery *query = [PFQuery queryWithClassName:@"chatLog"];
  __block int totalNumberOfEntries = 0;
  [query orderByAscending:@"createdAt"];
  [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
    if (!error) {
      // The count request succeeded. Log the count
      NSLog(@"There are currently %d entries", number);
      totalNumberOfEntries = number;
      // if (totalNumberOfEntries > [arrTempMsg count])
      {
        NSLog(@"Retrieving data");
        NSInteger theLimit;
        if (totalNumberOfEntries - [arrTempMsg count] > MAX_ENTRIES_LOADED) {
          theLimit = MAX_ENTRIES_LOADED;
        } else {
          theLimit = totalNumberOfEntries - [arrTempMsg count];
        }
        // query.limit = theLimit;
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects,
                                                  NSError *error) {
          if (!error) {
            // The find succeeded.
            NSLog(@"Successfully retrieved %lu chats.",
                  (unsigned long)objects.count);
            [arrTempMsg addObjectsFromArray:objects];
            [self.messages removeAllObjects];
            for (int i = 0; i < arrTempMsg.count; i++) {
              PFObject *obj = arrTempMsg[i];
              if ([obj objectForKey:@"image"]) {
                PFFile *file = [obj valueForKey:@"image"];

                UIImage *image = [UIImage imageNamed:@"loading"];
                JSQPhotoMediaItem *photoItem =
                    [[JSQPhotoMediaItem alloc] initWithImage:image];
                JSQMessage *photoMessage = [JSQMessage
                    messageWithSenderId:[obj valueForKey:@"sender"] ?: @"test"
                            displayName:[obj valueForKey:@"sender"] ?: @"test"
                                  media:photoItem];

                [self.messages addObject:photoMessage];
                [file getDataInBackgroundWithBlock:^(NSData *data,
                                                     NSError *error) {
                  if (!error) {
                    UIImage *image = [UIImage imageWithData:data];
                    JSQPhotoMediaItem *photoItem =
                        [[JSQPhotoMediaItem alloc] initWithImage:image];
                    JSQMessage *photoMessage1 = [JSQMessage
                        messageWithSenderId:[obj valueForKey:@"sender"]
                                displayName:[obj valueForKey:@"sender"]
                                      media:photoItem];
                    [self.messages replaceObjectAtIndex:i
                                             withObject:photoMessage1];
                    if (_refreshHandler) {
                      _refreshHandler();
                    };
                  }
                }];
              } else {
                NSString *text = [obj valueForKey:@"message"];
                if ([text hasSuffix:@"png"] || [text hasSuffix:@"jpeg"] ||
                    [text hasSuffix:@"jpg"] || [text hasSuffix:@"gif"]) {
                  UIImage *image = [UIImage imageNamed:@"loading"];
                  JSQPhotoMediaItem *photoItem =
                      [[JSQPhotoMediaItem alloc] initWithImage:image];
                  JSQMessage *photoMessage = [JSQMessage
                      messageWithSenderId:[obj valueForKey:@"sender"]
                              displayName:[obj valueForKey:@"sender"]
                                    media:photoItem];

                  [self.messages addObject:photoMessage];
                  dispatch_async(dispatch_get_main_queue(), ^{
                    NSData *data = [NSData
                        dataWithContentsOfURL:[NSURL URLWithString:text]];
                    UIImage *image = [UIImage imageWithData:data];
                    JSQPhotoMediaItem *photoItem =
                        [[JSQPhotoMediaItem alloc] initWithImage:image];
                    JSQMessage *photoMessage1 = [JSQMessage
                        messageWithSenderId:[obj valueForKey:@"sender"]
                                displayName:[obj valueForKey:@"sender"]
                                      media:photoItem];
                    [self.messages replaceObjectAtIndex:i
                                             withObject:photoMessage1];
                    if (_refreshHandler) {
                      _refreshHandler();
                    }

                  });
                } else {
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
      }

    } else {
      // The request failed, we'll keep the chatData count?
      number = (int)[self.messages count];
    }
  }];
}

- (void)addPhotoMediaMessagewithImage:(UIImage *)image
                withCompletionHandler:(void (^)(BOOL))completionHandler {

    NSUserDefaults *standerdDefaults = [NSUserDefaults standardUserDefaults];
  JSQPhotoMediaItem *photoItem =
      [[JSQPhotoMediaItem alloc] initWithImage:image];
  JSQMessage *photoMessage =
      [JSQMessage messageWithSenderId:[standerdDefaults valueForKey:@"username"]
                          displayName:[standerdDefaults valueForKey:@"username"]
                                media:photoItem];
  [self.messages addObject:photoMessage];

  NSData *data = UIImageJPEGRepresentation(image, 0.5f);
  PFFile *imageFile = [PFFile fileWithName:@"Image.jpg" data:data];

  // Save the image to Parse
  [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    if (!error) {
      NSUserDefaults *standerdDefault = [NSUserDefaults standardUserDefaults];
      // The image has now been uploaded to Parse. Associate it with a new
      // object
      PFObject *newPhotoObject = [PFObject objectWithClassName:@"chatLog"];
      [newPhotoObject setObject:imageFile forKey:@"image"];
      [newPhotoObject setObject:[standerdDefault valueForKey:@"username"]
                         forKey:@"sender"];
      [newPhotoObject setObject:[NSDate date] forKey:@"date"];

      [newPhotoObject
          saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
              completionHandler(YES);
            if (!error) {
              NSLog(@"Saved");
            } else {
              // Error
              NSLog(@"Error: %@ %@", error, [error userInfo]);
            }
          }];
    }
  }];
}

@end
