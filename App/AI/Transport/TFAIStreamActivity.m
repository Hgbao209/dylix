#import "TFAIStreamActivity.h"
#import "../../DylixI18n.h"
#import <math.h>

@interface TFAIStreamActivity ()
@property NSTimeInterval startedAt, lastPacketAt, lastContentAt;
@property BOOL receivedPacket, receivedContent;
@property NSString *phase;
@end

@implementation TFAIStreamActivity
- (instancetype)initAt:(NSTimeInterval)now {
 if((self=[super init])){_startedAt=now;_phase=@"waiting";}
 return self;
}
- (void)packetAt:(NSTimeInterval)now bytes:(NSUInteger)bytes {
 if(!bytes)return;
 self.receivedPacket=YES;self.lastPacketAt=now;
}
- (void)contentAt:(NSTimeInterval)now phase:(NSString *)phase {
 if(![@[@"reasoning",@"replying",@"tool_request"] containsObject:phase])return;
 self.receivedContent=YES;self.lastContentAt=now;self.phase=phase;
}
- (NSDictionary *)statusAt:(NSTimeInterval)now {
 NSTimeInterval packetIdle=MAX(0,now-(self.receivedPacket?self.lastPacketAt:self.startedAt));
 NSTimeInterval contentIdle=MAX(0,now-(self.receivedContent?self.lastContentAt:self.startedAt));
 BOOL waiting=!self.receivedContent||contentIdle>=15;
 NSString *message;
 if(packetIdle>=15){message=[NSString stringWithFormat:DXLoc(@"等待服务端数据 · %.0f 秒无新数据"),floor(packetIdle)];}
 else if(waiting&&self.receivedPacket){message=self.receivedContent?[NSString stringWithFormat:DXLoc(@"连接有数据，等待模型内容 · %.0f 秒无新内容"),floor(contentIdle)]:DXLoc(@"正在接收响应数据 · 尚未返回可显示内容");}
 else if(!self.receivedPacket&&!self.receivedContent){message=DXLoc(@"请求已发出 · 等待服务端响应");}
 else {NSString *label=[self.phase isEqual:@"reasoning"]?@"正在接收思考内容":[self.phase isEqual:@"tool_request"]?@"正在接收工具请求":DXLoc(@"正在接收回复");message=[NSString stringWithFormat:DXLoc(@"%@ · 最近内容 %.0f 秒前"),label,floor(contentIdle)];}
 return @{@"phase":self.phase?:@"waiting",@"waiting":@(waiting),@"hasPacket":@(self.receivedPacket),@"hasContent":@(self.receivedContent),@"packetIdleSeconds":@(packetIdle),@"contentIdleSeconds":@(contentIdle),@"elapsedSeconds":@(MAX(0,now-self.startedAt)),@"message":message};
}
@end
