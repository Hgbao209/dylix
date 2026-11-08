#import "DXRemoteAccess.h"
#import "../DylixI18n.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>
#import <sys/stat.h>
#import <TargetConditionals.h>
NSString *DXRemoteRandom(void){uint8_t bytes[32];if(SecRandomCopyBytes(kSecRandomDefault,sizeof(bytes),bytes)!=errSecSuccess)return nil;NSMutableString *s=[NSMutableString new];for(NSUInteger i=0;i<sizeof(bytes);i++)[s appendFormat:@"%02x",bytes[i]];return s;}
NSString *DXRemoteHash(NSString *text){NSData *d=[text dataUsingEncoding:NSUTF8StringEncoding];uint8_t bytes[CC_SHA256_DIGEST_LENGTH];CC_SHA256(d.bytes,(CC_LONG)d.length,bytes);NSMutableString *s=[NSMutableString new];for(NSUInteger i=0;i<sizeof(bytes);i++)[s appendFormat:@"%02x",bytes[i]];return s;}
static NSDictionary *Fail(NSInteger status,NSString *code,NSString *message){return @{@"status":@(status),@"error":@{@"code":code,@"message":message}};}
static BOOL Equal(NSString *a,NSString *b){if(!a||!b)return NO;NSData *x=[a dataUsingEncoding:NSUTF8StringEncoding],*y=[b dataUsingEncoding:NSUTF8StringEncoding];if(x.length!=y.length)return NO;const uint8_t *p=x.bytes,*q=y.bytes;uint8_t diff=0;for(NSUInteger i=0;i<x.length;i++)diff|=p[i]^q[i];return diff==0;}
@interface DXRemoteAccess ()
@property NSString *pairingCode,*store;
@property NSTimeInterval codeExpiry;
@property BOOL fixedCode;
@property NSMutableDictionary<NSString *,NSMutableDictionary *> *requests;
@property NSMutableArray<NSMutableDictionary *> *records;
@property NSMutableArray<NSDictionary *> *audit;
@property NSMutableDictionary<NSString *,NSMutableDictionary *> *attempts;
@end
@implementation DXRemoteAccess
- (instancetype)initWithStore:(NSString *)store{
 if((self=[super init])){_store=store;_requests=[NSMutableDictionary new];_records=[NSMutableArray new];_audit=[NSMutableArray new];_attempts=[NSMutableDictionary new];
  NSDictionary *attributes=[NSFileManager.defaultManager attributesOfItemAtPath:store error:nil];
  NSData *stored=[attributes[NSFileSize] unsignedLongLongValue]<=65536?[NSData dataWithContentsOfFile:store]:nil;
  id values=[NSJSONSerialization JSONObjectWithData:stored?:NSData.data options:0 error:nil];
  if([values isKindOfClass:NSArray.class])for(id entry in values){if(_records.count>=32)break;if([entry isKindOfClass:NSDictionary.class]&&[entry[@"id"] isKindOfClass:NSString.class]&&[entry[@"name"] isKindOfClass:NSString.class]&&[entry[@"hash"] isKindOfClass:NSString.class]&&[entry[@"hash"] length]==64&&[entry[@"expiresAt"] isKindOfClass:NSNumber.class]&&[entry[@"expiresAt"] doubleValue]>NSDate.date.timeIntervalSince1970){if([entry[@"id"] length]>64||[entry[@"name"] length]>64)continue;
  NSMutableDictionary *e=[@{@"id":entry[@"id"],@"name":entry[@"name"],@"hash":entry[@"hash"],@"expiresAt":entry[@"expiresAt"],@"createdAt":[entry[@"createdAt"] isKindOfClass:NSNumber.class]?entry[@"createdAt"]:@0,@"lastSeen":@0,@"permission":[entry[@"permission"] isEqual:@"workspace"]?@"workspace":([entry[@"permission"] isEqual:@"webdav"]?@"webdav":@"overview:read"),@"projectID":[entry[@"projectID"] isKindOfClass:NSString.class]?entry[@"projectID"]:@"",@"readOnly":@([entry[@"readOnly"] boolValue])} mutableCopy];[_records addObject:e];}}
 }return self;
}
- (BOOL)save:(NSError **)error{
 NSString *parent=self.store.stringByDeletingLastPathComponent;if(![NSFileManager.defaultManager createDirectoryAtPath:parent withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions:@0700} error:error])return NO;
 NSMutableArray *safe=[NSMutableArray new];for(NSDictionary *e in self.records)[safe addObject:@{@"id":e[@"id"],@"name":e[@"name"],@"hash":e[@"hash"],@"expiresAt":e[@"expiresAt"],@"createdAt":e[@"createdAt"]?:@0,@"permission":e[@"permission"]?:@"overview:read",@"projectID":e[@"projectID"]?:@"",@"readOnly":e[@"readOnly"]?:@NO}];
 NSData *data=[NSJSONSerialization dataWithJSONObject:safe options:0 error:error];if(!data)return NO;
#if TARGET_OS_IPHONE
 NSDataWritingOptions options=NSDataWritingAtomic|NSDataWritingFileProtectionComplete;
#else
 NSDataWritingOptions options=NSDataWritingAtomic;
#endif
 if(![data writeToFile:self.store options:options error:error])return NO;if(chmod(self.store.fileSystemRepresentation,0600)!=0){[NSFileManager.defaultManager removeItemAtPath:self.store error:nil];if(error)*error=[NSError errorWithDomain:@"Dylix.Remote" code:1 userInfo:@{NSLocalizedDescriptionKey:DXLoc(@"保存设备授权的文件权限失败")}];return NO;}return YES;
}
- (void)record:(NSString *)event{[self.audit addObject:@{@"event":event,@"timestamp":@(NSDate.date.timeIntervalSince1970)}];while(self.audit.count>200)[self.audit removeObjectAtIndex:0];}
- (NSArray *)events{return self.audit.copy;}
- (void)prune{NSTimeInterval now=NSDate.date.timeIntervalSince1970;for(NSString *key in self.requests.allKeys)if(now-[self.requests[key][@"createdAt"] doubleValue]>60)[self.requests removeObjectForKey:key];for(NSString *key in self.attempts.allKeys)if(now-[self.attempts[key][@"time"] doubleValue]>60)[self.attempts removeObjectForKey:key];[self.records filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary *e,NSDictionary *b){return [e[@"expiresAt"] doubleValue]>now;}]];}
- (void)rotateCode{self.fixedCode=NO;[self prune];NSString *random=DXRemoteRandom();if(!random){self.pairingCode=@"";self.codeExpiry=0;return;}unsigned long long value=strtoull([random substringToIndex:12].UTF8String,NULL,16);self.pairingCode=[NSString stringWithFormat:@"%08llu",value%100000000];self.codeExpiry=NSDate.date.timeIntervalSince1970+300;}
- (NSArray *)pending{[self prune];NSMutableArray *a=[NSMutableArray new];for(NSDictionary *r in self.requests.allValues)if([r[@"status"] isEqual:@"pending"])[a addObject:@{@"id":r[@"id"],@"name":r[@"name"],@"createdAt":r[@"createdAt"],@"workspace":r[@"workspace"]?:@NO}];return a;}
- (NSArray *)devices{[self prune];NSMutableArray *a=[NSMutableArray new];for(NSDictionary *r in self.records)[a addObject:@{@"id":r[@"id"],@"name":r[@"name"],@"createdAt":r[@"createdAt"]?:@0,@"expiresAt":r[@"expiresAt"],@"online":@(NSDate.date.timeIntervalSince1970-[r[@"lastSeen"] doubleValue]<30),@"permission":r[@"permission"]?:@"overview:read",@"projectID":r[@"projectID"]?:@"",@"readOnly":r[@"readOnly"]?:@NO}];return a;}
- (BOOL)rate:(NSString *)peer{
 [self prune];for(NSString *key in @[@"global",[@"peer:" stringByAppendingString:peer]]){NSMutableDictionary *r=self.attempts[key];if(!r){r=[@{@"time":@(NSDate.date.timeIntervalSince1970),@"count":@0} mutableCopy];self.attempts[key]=r;}NSUInteger n=[r[@"count"] unsignedIntegerValue];if(n>=([key isEqual:@"global"]?20:5))return NO;r[@"count"]=@(n+1);}return YES;
}
- (NSDictionary *)beginPair:(NSDictionary *)body peer:(NSString *)peer{
 if(![self rate:peer])return Fail(429,@"rate_limited",DXLoc(@"配对请求过多，请一分钟后再试"));
 if(![body[@"code"] isKindOfClass:NSString.class]||!self.pairingCode.length||(!self.fixedCode&&self.codeExpiry<NSDate.date.timeIntervalSince1970)||!Equal(body[@"code"],self.pairingCode))return Fail(403,@"invalid_code",DXLoc(@"配对码无效或已过期"));
 if(body[@"workspace"]&&![body[@"workspace"] isKindOfClass:NSNumber.class])return Fail(400,@"invalid_permission",DXLoc(@"权限参数需为布尔值"));
 NSString *name=body[@"name"];if(![name isKindOfClass:NSString.class]||!name.length||name.length>64||[name rangeOfCharacterFromSet:NSCharacterSet.controlCharacterSet].location!=NSNotFound)return Fail(400,@"invalid_device",DXLoc(@"设备名称需为 1–64 个可见字符"));
 if(self.requests.count>=8||self.records.count>=32)return Fail(429,@"device_limit",DXLoc(@"待确认或已授权设备已达上限"));

 NSString *token=DXRemoteRandom(),*device=NSUUID.UUID.UUIDString;if(!token||!device)return Fail(503,@"entropy_unavailable",DXLoc(@"随机数服务未就绪"));
 NSMutableDictionary *entry=[@{ @"id":device,@"name":name,@"hash":DXRemoteHash(token),@"createdAt":@(NSDate.date.timeIntervalSince1970),@"expiresAt":@(NSDate.date.timeIntervalSince1970+30*86400),@"lastSeen":@0,@"permission":[body[@"workspace"] boolValue]?@"workspace":@"overview:read"} mutableCopy];
 [self.records addObject:entry];NSError *saveError=nil;if(![self save:&saveError]){[self.records removeObject:entry];return Fail(503,@"storage_failed",saveError.localizedDescription?:DXLoc(@"授权保存失败"));}
 if(!self.fixedCode){self.pairingCode=@"";self.codeExpiry=0;}
 [self record:@"pair_approved_direct"];
 return @{ @"status":@200,@"data":@{@"state":@"approved",@"deviceID":device},@"token":token};

}
- (BOOL)setFixedCode:(NSString *)code error:(NSError **)error{
 [self prune];if(![code isKindOfClass:NSString.class]||code.length<6||code.length>12||[code rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"0123456789"].invertedSet].location!=NSNotFound){if(error)*error=[NSError errorWithDomain:@"Dylix.Remote" code:2 userInfo:@{NSLocalizedDescriptionKey:DXLoc(@"授权码需为 6–12 位数字")}];return NO;}self.fixedCode=YES;self.pairingCode=code;self.codeExpiry=0;[self record:@"pair_code_fixed"];return YES;}
- (BOOL)approve:(NSString *)identifier accepted:(BOOL)accepted error:(NSError **)error{
 [self prune];NSMutableDictionary *r=self.requests[identifier];if(![r[@"status"] isEqual:@"pending"])return NO;
 if(!accepted){r[@"status"]=@"denied";[self record:@"pair_denied"];return YES;}
 if(self.records.count>=32)return NO;NSString *token=DXRemoteRandom();if(!token)return NO;
 NSString *device=NSUUID.UUID.UUIDString;NSMutableDictionary *entry=[@{@"id":device,@"name":r[@"name"],@"hash":DXRemoteHash(token),@"createdAt":@(NSDate.date.timeIntervalSince1970),@"expiresAt":@(NSDate.date.timeIntervalSince1970+30*86400),@"lastSeen":@0,@"permission":[r[@"workspace"] boolValue]?@"workspace":@"overview:read"} mutableCopy];[self.records addObject:entry];
 if(![self save:error]){[self.records removeObject:entry];return NO;}r[@"token"]=token;r[@"status"]=@"approved";r[@"deviceID"]=device;[self record:@"pair_approved"];return YES;
}
- (NSDictionary *)claimPair:(NSString *)identifier secret:(NSString *)secret{
 [self prune];NSMutableDictionary *r=self.requests[identifier];if(!r||!Equal(DXRemoteHash(secret?:@""),r[@"secretHash"]))return Fail(403,@"invalid_pair",DXLoc(@"配对凭据无效或已过期"));
 if([r[@"status"] isEqual:@"pending"])return @{@"status":@202,@"data":@{@"state":@"pending"}};
 if([r[@"status"] isEqual:@"denied"]){[self.requests removeObjectForKey:identifier];return Fail(403,@"pair_denied",DXLoc(@"手机已拒绝此设备"));}
 NSDictionary *result=@{@"status":@200,@"data":@{@"state":@"approved",@"deviceID":r[@"deviceID"]},@"token":r[@"token"]};[self.requests removeObjectForKey:identifier];return result;
}
- (NSDictionary *)authenticateCookie:(NSString *)cookie name:(NSString *)name{
 [self prune];NSString *token=nil;for(NSString *part in [cookie componentsSeparatedByString:@";"]){NSString *p=[part stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet],*prefix=[name stringByAppendingString:@"="];if([p hasPrefix:prefix]){if(token)return nil;token=[p substringFromIndex:prefix.length];}}
 if(token.length!=64)return nil;NSString *hash=DXRemoteHash(token);for(NSMutableDictionary *r in self.records)if(Equal(hash,r[@"hash"])){r[@"lastSeen"]=@(NSDate.date.timeIntervalSince1970);return @{@"id":r[@"id"],@"name":r[@"name"],@"csrf":[self csrfForToken:token],@"permission":r[@"permission"]?:@"overview:read",@"projectID":r[@"projectID"]?:@"",@"readOnly":r[@"readOnly"]?:@NO};}return nil;
}
- (NSString *)csrfForToken:(NSString *)token{return DXRemoteHash([@"Dylix.Remote.CSRF:" stringByAppendingString:token]);}
- (BOOL)revoke:(NSString *)identifier error:(NSError **)error{
 NSArray *previous=self.records.copy;if(identifier){[self.records filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary *e,NSDictionary *b){return ![e[@"id"] isEqual:identifier];}]];}else{[self.records removeAllObjects];[self.requests removeAllObjects];}
 if(![self save:error]){self.records=[previous mutableCopy];return NO;}
 // Issued but unclaimed tokens are also revoked, never handed to a disconnected device.
 for(NSString *key in self.requests.allKeys)if([self.requests[key][@"deviceID"] isEqual:identifier])[self.requests removeObjectForKey:key];
 [self record:identifier?@"device_revoked":@"all_devices_revoked"];return YES;
}
- (NSDictionary *)issueDAV:(NSString *)project readOnly:(BOOL)readOnly error:(NSError **)error{
 [self prune];if(self.records.count>=32)return nil;NSString *token=DXRemoteRandom();if(!token)return nil;
 NSMutableDictionary *entry=[@{@"id":NSUUID.UUID.UUIDString,@"name":DXLoc(@"WebDAV 客户端"),@"hash":DXRemoteHash(token),@"createdAt":@(NSDate.date.timeIntervalSince1970),@"expiresAt":@(NSDate.date.timeIntervalSince1970+86400),@"lastSeen":@0,@"permission":@"webdav",@"projectID":project,@"readOnly":@(readOnly)} mutableCopy];[self.records addObject:entry];if(![self save:error]){[self.records removeObject:entry];return nil;}[self record:@"webdav_credential_issued"];return @{@"username":@"dylix",@"password":token,@"id":entry[@"id"]};
}
- (void)resetEphemeral{[self.requests removeAllObjects];[self.attempts removeAllObjects];self.pairingCode=@"";self.codeExpiry=0;self.fixedCode=NO;for(NSMutableDictionary *r in self.records)r[@"lastSeen"]=@0;}
@end
