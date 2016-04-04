//
//  GroupChatViewController.h
//  GroupChatDemo
//
//  Created by Vaibhav Mistry on 4/3/16.
//  Copyright © 2016 Vaibhav Mistry. All rights reserved.
//


// Import all the things
#import "JSQMessages.h"
#import "GroupChatModelData.h"
#import "NSUserDefaults+DemoSettings.h"
#import <Parse/Parse.h>


@class GroupChatViewController;

@protocol JSQDemoViewControllerDelegate <NSObject>
- (void)didDismissJSQDemoViewController:(GroupChatViewController *)vc;
@end


@interface GroupChatViewController : JSQMessagesViewController <UIActionSheetDelegate, JSQMessagesComposerTextViewPasteDelegate, UITextFieldDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (weak, nonatomic) id<JSQDemoViewControllerDelegate> delegateModal;
@property (strong, nonatomic) GroupChatModelData *chatData;


@end
