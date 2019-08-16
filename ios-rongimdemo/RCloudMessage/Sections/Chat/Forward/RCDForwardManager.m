//
//  RCDForwardManager.m
//  SealTalk
//
//  Created by 孙浩 on 2019/6/17.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCDForwardManager.h"

@interface RCDForwardManager ()
@property (nonatomic, strong) UIViewController *viewController;

@property (nonatomic, assign) NSInteger friendCount;
@property (nonatomic, assign) NSInteger groupCount;
@end

@implementation RCDForwardManager

+ (RCDForwardManager *)sharedInstance {
    static RCDForwardManager *instance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

- (void)showForwardAlertViewInViewController:(UIViewController *)viewController {
    self.viewController = viewController;
    if (self.isMultiSelect) {
        RCDForwardAlertView *alertView = [RCDForwardAlertView alertViewWithSelectedContacts:[self.selectedContactArray copy]];
        alertView.messageArray = self.selectedMessages;
        alertView.delegate = self;
        [alertView show];
    } else {
        RCDForwardAlertView *alertView = [RCDForwardAlertView alertViewWithModel:self.toConversation];
        alertView.messageArray = self.selectedMessages;
        alertView.delegate = self;
        [alertView show];
    }
}

- (void)forwardAlertView:(RCDForwardAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self doForwardMessage:alertView];
    }
}

- (void)doForwardMessage:(RCDForwardAlertView *)alertView {
    for (RCMessageModel *message in self.selectedMessages) {
        if (self.isMultiSelect) {
            for (RCDForwardCellModel *model in self.selectedContactArray) {
                [self forwardWithConversationType:model.conversationType targetId:model.targetId message:message];
            }
        } else {
            [self forwardWithConversationType:self.toConversation.conversationType targetId:self.toConversation.targetId message:message];
        }
    }
}

- (void)forwardWithConversationType:(RCConversationType)type targetId:(NSString *)targetId message:(RCMessageModel *)message {
    if (self.willForwardMessageBlock) {
        self.willForwardMessageBlock(type,targetId);
        [self dismiss];
    }else{
        __weak typeof(self) weakSelf = self;
        [[RCIM sharedRCIM] sendMessage:type targetId:targetId content:message.content pushContent:nil pushData:nil success:^(long messageId) {
            [weakSelf dismiss];
        } error:^(RCErrorCode nErrorCode, long messageId) {
            [weakSelf dismiss];
        }];
        [NSThread sleepForTimeInterval:0.4];
    }
}

- (void)forwardEnd {
    [self dismiss];
}

- (void)dismiss {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.viewController dismissViewControllerAnimated:YES completion:nil];
        [self clear];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RCDForwardMessageEnd" object:nil];
    });
}

- (NSArray *)getForwardModelArray {
    return [self.selectedContactArray copy];
}

- (void)addForwardModel:(RCDForwardCellModel *)model {
    [self.selectedContactArray addObject:model];
    if (model.conversationType == ConversationType_GROUP) {
        self.groupCount ++;
    } else if (model.conversationType == ConversationType_PRIVATE) {
        self.friendCount ++;
    }
}
- (void)removeForwardModel:(RCDForwardCellModel *)model {
    NSArray *modelArray = [self getForwardModelArray];
    for (RCDForwardCellModel *cellModel in modelArray) {
        if ([cellModel.targetId isEqualToString:model.targetId]) {
            [self.selectedContactArray removeObject:cellModel];
        }
    }
    if (model.conversationType == ConversationType_GROUP) {
        self.groupCount --;
    } else if (model.conversationType == ConversationType_PRIVATE) {
        self.friendCount --;
    }
}

- (void)clearForwardModelArray {
    [self.selectedContactArray removeAllObjects];
    self.groupCount = 0;
    self.friendCount = 0;
}

- (BOOL)modelIsContains:(NSString *)targetId {
    NSArray *modelArray = [self getForwardModelArray];
    for (RCDForwardCellModel *model in modelArray) {
        if ([model.targetId isEqualToString:targetId]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)allSelectedMessagesAreLegal {
    for (RCMessageModel *model in self.selectedMessages) {
        BOOL result = [self isLegalMessage:model];
        if (!result) {
            return result; // return no
        }
    }
    return YES;
}

- (BOOL)isLegalMessage:(RCMessageModel *)model {
    //未成功发送的消息不可转发
    if (model.sentStatus == SentStatus_SENDING || model.sentStatus == SentStatus_FAILED ||
        model.sentStatus == SentStatus_CANCELED) {
        return NO;
    }
    if ([[self blackList] containsObject:model.objectName]) {
        return NO;
    }
    return YES;
}

- (NSArray<NSString *> *)blackList {
    static NSArray *blackList = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        blackList = @[
                      @"RC:VCAccept", @"RC:VCHangup", @"RC:VCInvite", @"RC:VCModifyMedia", @"RC:VCModifyMem", @"RC:VCRinging",
                      @"RC:VCSummary", @"RC:RLStart", @"RC:RLEnd", @"RC:RLJoin", @"RC:RLQuit", @"RCJrmf:RpMsg", @"RC:VcMsg"
                      ];
    });
    return blackList;
}

- (void)clear {
    self.isForward = NO;
    self.isMultiSelect = NO;
    self.selectedMessages = nil;
    self.toConversation = nil;
    [self.selectedContactArray removeAllObjects];
    self.friendCount = 0;
    self.groupCount = 0;
}

- (NSMutableArray *)selectedContactArray {
    if (!_selectedContactArray) {
        _selectedContactArray = [NSMutableArray array];
    }
    return _selectedContactArray;
}

@end
