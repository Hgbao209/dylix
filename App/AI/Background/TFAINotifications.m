#import "TFAINotifications.h"
#import "../../DylixI18n.h"
#import <UserNotifications/UserNotifications.h>
#import <UIKit/UIKit.h>
@interface TFAINotificationDelegate : NSObject <UNUserNotificationCenterDelegate>
@end
@implementation TFAINotificationDelegate
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completion{NSDictionary *info=response.notification.request.content.userInfo;if([info[@"buildTaskID"] length]){dispatch_async(dispatch_get_main_queue(),^{[NSNotificationCenter.defaultCenter postNotificationName:@"TFAIOpenBuildQueue" object:nil userInfo:info];});completion();return;}if([info[@"sessionID"] length])dispatch_async(dispatch_get_main_queue(),^{[NSNotificationCenter.defaultCenter postNotificationName:@"TFAIOpenConversation" object:nil userInfo:info];});completion();}
@end
void TFAINotificationsRegister(void){static TFAINotificationDelegate *delegate;static dispatch_once_t once;dispatch_once(&once,^{delegate=[TFAINotificationDelegate new];UNUserNotificationCenter.currentNotificationCenter.delegate=delegate;});}
void TFAINotificationsRequest(void){TFAINotificationsRegister();
 UNUserNotificationCenter *center=UNUserNotificationCenter.currentNotificationCenter;
 [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings){if(settings.authorizationStatus==UNAuthorizationStatusNotDetermined)[center requestAuthorizationWithOptions:UNAuthorizationOptionAlert|UNAuthorizationOptionSound completionHandler:^(BOOL granted,NSError *error){}];}];
}
void TFAINotifyCompletion(NSString *session,NSString *title,NSString *project,BOOL success){
 if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{TFAINotifyCompletion(session,title,project,success);});return;}
 __block UIBackgroundTaskIdentifier lease=UIBackgroundTaskInvalid;void(^release)(void)=^{dispatch_async(dispatch_get_main_queue(),^{UIBackgroundTaskIdentifier task=lease;lease=UIBackgroundTaskInvalid;if(task!=UIBackgroundTaskInvalid)[UIApplication.sharedApplication endBackgroundTask:task];});};
 lease=[UIApplication.sharedApplication beginBackgroundTaskWithName:@"Dylix AI notification" expirationHandler:release];
 UNMutableNotificationContent *content=[UNMutableNotificationContent new];content.title=success?@"AI 处理完成":DXLoc(@"AI 任务需要查看");content.body=title.length?[NSString stringWithFormat:@"%@ · %@",title,success?@"回复和操作记录已保存":DXLoc(@"记录已保存，可返回继续分析")]:DXLoc(@"返回 Dylix 查看会话记录");content.sound=UNNotificationSound.defaultSound;content.threadIdentifier=session?:@"ai";content.userInfo=@{@"sessionID":session?:@"",@"projectID":project?:@"general"};
 UNNotificationRequest *request=[UNNotificationRequest requestWithIdentifier:[@"ai-finished-" stringByAppendingString:session?:NSUUID.UUID.UUIDString] content:content trigger:nil];
 [UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:request withCompletionHandler:^(NSError *error){if(error)NSLog(@"[AI notification] %@",error.localizedDescription);release();}];
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW,5*NSEC_PER_SEC),dispatch_get_main_queue(),release);
}

void TFAINotifyBuildCompletion(NSString *task,NSString *project,BOOL success){if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{TFAINotifyBuildCompletion(task,project,success);});return;}UNMutableNotificationContent *content=[UNMutableNotificationContent new];content.title=success?@"本机构建完成":DXLoc(@"本机构建需要查看");content.body=[NSString stringWithFormat:@"%@ · %@",project?:DXLoc(@"Dylix项目"),success?@"产物与日志已保存，运行待验证":DXLoc(@"查看诊断、取消状态与检查点")];content.sound=UNNotificationSound.defaultSound;content.threadIdentifier=@"dylix-build-queue";content.userInfo=@{@"buildTaskID":task?:@""};UNNotificationRequest *request=[UNNotificationRequest requestWithIdentifier:[@"build-finished-" stringByAppendingString:task?:NSUUID.UUID.UUIDString] content:content trigger:nil];[UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:request withCompletionHandler:nil];}
