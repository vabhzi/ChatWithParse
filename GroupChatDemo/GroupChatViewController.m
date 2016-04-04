//
//  GroupChatViewController.m
//  GroupChatDemo
//
//  Created by Vaibhav Mistry on 4/3/16.
//  Copyright © 2016 Vaibhav Mistry. All rights reserved.
//

#import "GroupChatViewController.h"
#import "AppDelegate.h"

@interface GroupChatViewController()
{
    UIAlertAction *okAction;
    UIImage *pickedImage;
}
@end

@implementation GroupChatViewController

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    AppDelegate *appdelegate = [[UIApplication sharedApplication]delegate];
    appdelegate.refreshHandler = ^{
        [self.chatData loadLocalChatwithCompletionHandler:^(BOOL isSuccess) {
            [self.collectionView reloadData];
            if(_chatData.messages.count)
            {
                [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:_chatData.messages.count-1 inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
            }
            
        }];
    };
    
    self.title = @"JSQMessages";
    
    /**
     *  You MUST set your senderId and display name
     */
    NSUserDefaults *standerdDefaults = [NSUserDefaults standardUserDefaults];
    if([standerdDefaults valueForKey:@"username"])
    {
        self.senderId = [standerdDefaults valueForKey:@"username"];
        self.senderDisplayName = [standerdDefaults valueForKey:@"username"];
    }
    
    self.inputToolbar.contentView.textView.pasteDelegate = self;
    
    self.chatData = [[GroupChatModelData alloc] init];
    
    typeof(self) __weak weakSelf = self;
    typeof(_chatData) __weak weakChat = _chatData;
    self.chatData.refreshHandler = ^{
        [weakSelf.collectionView reloadData];
        if(weakChat.messages.count)
        {
            [weakSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:_chatData.messages.count-1 inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
        }
    };
    
    
    self.showLoadEarlierMessagesHeader = NO;
    
    
    /**
     *  Register custom menu actions for cells.
     */
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(customAction:)];
    [UIMenuController sharedMenuController].menuItems = @[ [[UIMenuItem alloc] initWithTitle:@"Custom Action"
                                                                                      action:@selector(customAction:)] ];
    
    /**
     *  OPT-IN: allow cells to be deleted
     */
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(delete:)];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.collectionView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSUserDefaults *standerdDefaults = [NSUserDefaults new];
    
    if([standerdDefaults valueForKey:@"username"])
    {
        /**
         *  Load previous messsages for the first time application runs
         */
        [self.chatData loadLocalChatwithCompletionHandler:^(BOOL isSuccess) {
            [self.collectionView reloadData];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                /**
                 *  Scrolling to the latest message at bottom
                 */
                [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:_chatData.messages.count-1 inSection:0]
                                            atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
            });
            
        }];
    }
    else
    {
        /**
         *  Input Alert for entering Username for Chat
         */
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@""
                                                                                 message:@"Enter Username"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
         {
             textField.delegate = self;
             textField.placeholder = @"eg. John Dough";
         }];
        
        okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                              
                                              /**
                                               *  Setting username in the NSUserDefaults to use while re-login
                                               */
                                              
                                              UITextField *txtUserName = alertController.textFields.firstObject;
                                             
                                              NSUserDefaults *standerdDefaults = [NSUserDefaults new];
                                              [standerdDefaults setValue:txtUserName.text forKey:@"username"];
                                              self.senderDisplayName = txtUserName.text;
                                              self.senderId    = txtUserName.text;
                                              
                                              [self.chatData loadLocalChatwithCompletionHandler:^(BOOL isSuccess) {
                                                  [self.collectionView reloadData];
                                                  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                     
                                                      /**
                                                       *  Scrolling to the latest message at bottom
                                                       */
                                                      [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:_chatData.messages.count-1 inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
                                                  });
                                                  
                                              }];
                                              
                                          }];
        okAction.enabled = NO;
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    self.collectionView.collectionViewLayout.springinessEnabled = [NSUserDefaults springinessSetting];
    
}

#pragma mark - UITextField Delegate Method
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    NSString *finalString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [okAction setEnabled:(finalString.length >= 5)];
    return YES;
}




#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    /**
     *  A list of extensions to check against
     */
    NSArray *imageExtensions = @[@"png", @"jpg", @"gif"]; //...
    
    NSString *extension = [text pathExtension];
    if([imageExtensions containsObject:extension])
    {
        /**
         *  Generating Image From Using Data
         */
        NSURL *url = [NSURL URLWithString:text];
        NSData *data = [NSData dataWithContentsOfURL:url];
        UIImage *img = [[UIImage alloc] initWithData:data];
        typeof(self) __weak weakSelf = self;
        [self.chatData addPhotoMediaMessagewithImage:img withCompletionHandler:^(BOOL isSuccess) {
            [weakSelf.chatData loadLocalChatwithCompletionHandler:^(BOOL isSuccess) {
                [weakSelf.collectionView reloadData];
            }];
        }];
    }
    else
    {
        /**
         *  Generating Message
         */
        JSQMessage *message = [[JSQMessage alloc] initWithSenderId:senderId
                                                 senderDisplayName:senderDisplayName
                                                              date:date
                                                              text:text];
        
        [self.chatData.messages addObject:message];
        
    }
    
    
    
    /**
     *  Going for the parsing
     *  "chatLog" is a Class name used for all the chat to be stored on Parse
     */
    PFObject *newMessage = [PFObject objectWithClassName:@"chatLog"];
    [newMessage setObject:text forKey:@"message"];
    [newMessage setObject:senderDisplayName forKey:@"sender"];
    [newMessage setObject:date forKey:@"date"];
    //[newMessage saveInBackground];
    [newMessage saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if(succeeded)
        {
            [self.chatData loadLocalChatwithCompletionHandler:^(BOOL isSuccess) {
                [self finishSendingMessageAnimated:YES];
            }];
            
            
        }
    }];
    
    
    /**
     *  Sending Push Notification using Parse
     */
    PFPush *push = [[PFPush alloc] init];
    [push setChannel:@"global"];
    [push setMessage:[NSString stringWithFormat:@"%@ : %@",senderDisplayName,text]];
    [push sendPushInBackground];
    
}

- (void)didPressAccessoryButton:(UIButton *)sender
{
    [self.inputToolbar.contentView.textView resignFirstResponder];
    
    /**
     *  Image Picker Controller initialization
     */
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:nil];
}


#pragma mark - UIImagePickerController Delegate Methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    pickedImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    
    typeof(self) __weak weakSelf = self;
    [self.chatData addPhotoMediaMessagewithImage:pickedImage withCompletionHandler:^(BOOL i) {
        [weakSelf.chatData loadLocalChatwithCompletionHandler:^(BOOL j) {
            [JSQSystemSoundPlayer jsq_playMessageSentSound];
            [weakSelf.collectionView reloadData];
        }];
    }];
}



#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.chatData.messages objectAtIndex:indexPath.item];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath
{
    [self.chatData.messages removeObjectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  You may return nil here if you do not want bubbles.
     *  In this case, you should set the background color of your collection view cell's textView.
     *
     *  Otherwise, return your previously created bubble image data objects.
     */
    
    JSQMessage *message = [self.chatData.messages objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.chatData.outgoingBubbleImageData;
    }
    
    return self.chatData.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Return `nil` here if you do not want avatars.
     *  If you do return `nil`, be sure to do the following in `viewDidLoad`:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
     *
     *  It is possible to have only outgoing avatars or only incoming avatars, too.
     */
    
    /**
     *  Return your previously created avatar image data objects.
     *
     *  Note: these the avatars will be sized according to these values:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize
     *
     *  Override the defaults in `viewDidLoad`
     */
    JSQMessage *message = [self.chatData.messages objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        if (![NSUserDefaults outgoingAvatarSetting]) {
            return nil;
        }
    }
    else {
        if (![NSUserDefaults incomingAvatarSetting]) {
            return nil;
        }
    }
    
    
    return [self.chatData.avatars objectForKey:message.senderId];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
     *  The other label text delegate methods should follow a similar pattern.
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        JSQMessage *message = [self.chatData.messages objectAtIndex:indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self.chatData.messages objectAtIndex:indexPath.item];
    
    /**
     *  iOS7-style sender name labels
     */
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.chatData.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }
    
    /**
     *  Don't specify attributes to use the defaults.
     */
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.chatData.messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    JSQMessage *msg = [self.chatData.messages objectAtIndex:indexPath.item];
    
    if (!msg.isMediaMessage) {
        
        if ([msg.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor blackColor];
        }
        else {
            cell.textView.textColor = [UIColor whiteColor];
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    return cell;
}



#pragma mark - Custom menu items

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(customAction:)) {
        return YES;
    }
    
    return [super collectionView:collectionView canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(customAction:)) {
        [self customAction:sender];
        return;
    }
    
    [super collectionView:collectionView performAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)customAction:(id)sender
{
    
}



#pragma mark - JSQMessages collection view flow layout delegate

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
     */
    
    /**
     *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
     *  The other label height delegate methods should follow similarly
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  iOS7-style sender name labels
     */
    JSQMessage *currentMessage = [self.chatData.messages objectAtIndex:indexPath.item];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.chatData.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    NSLog(@"Load earlier messages!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped message bubble!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}

#pragma mark - JSQMessagesComposerTextViewPasteDelegate methods


- (BOOL)composerTextView:(JSQMessagesComposerTextView *)textView shouldPasteWithSender:(id)sender
{
    if ([UIPasteboard generalPasteboard].image) {
        // If there's an image in the pasteboard, construct a media item with that image and `send` it.
        JSQPhotoMediaItem *item = [[JSQPhotoMediaItem alloc] initWithImage:[UIPasteboard generalPasteboard].image];
        JSQMessage *message = [[JSQMessage alloc] initWithSenderId:self.senderId
                                                 senderDisplayName:self.senderDisplayName
                                                              date:[NSDate date]
                                                             media:item];
        [self.chatData.messages addObject:message];
        [self finishSendingMessage];
        return NO;
    }
    return YES;
}

@end
