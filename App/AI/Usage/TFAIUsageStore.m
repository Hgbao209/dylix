#import "TFAIUsageStore.h"
#import "../../DylixI18n.h"
#import <math.h>
#import <TargetConditionals.h>
static NSDictionary *UDict(id v){return [v isKindOfClass:NSDictionary.class]?v:@{};}
static NSNumber *UCount(id v){if(![v isKindOfClass:NSNumber.class]||CFGetTypeID((__bridge CFTypeRef)v)==CFBooleanGetTypeID())return nil;double n=[v doubleValue];return isfinite(n)&&n>=0&&n<=1e15&&floor(n)==n?@([v unsignedLongLongValue]):nil;}
static void UPut(NSMutableDictionary *d,NSString *k,id v){NSNumber *n=UCount(v);if(n)d[k]=n;}
NSDictionary *TFAINormalizeUsage(NSDictionary *raw,NSString *wire){
 NSDictionary *u=UDict(raw);NSMutableDictionary *d=[NSMutableDictionary new];
 if([wire isEqual:@"anthropic"]){
  UPut(d,@"uncachedInput",u[@"input_tokens"]);UPut(d,@"cachedInput",u[@"cache_read_input_tokens"]);UPut(d,@"cacheWrite",u[@"cache_creation_input_tokens"]);UPut(d,@"output",u[@"output_tokens"]);
 }else if([wire isEqual:@"gemini"]){
  UPut(d,@"promptInput",u[@"promptTokenCount"]);UPut(d,@"toolInput",u[@"toolUsePromptTokenCount"]);UPut(d,@"cachedInput",u[@"cachedContentTokenCount"]);UPut(d,@"visibleOutput",u[@"candidatesTokenCount"]);UPut(d,@"reasoning",u[@"thoughtsTokenCount"]);UPut(d,@"providerTotal",u[@"totalTokenCount"]);
 }else{
  UPut(d,@"input",u[@"prompt_tokens"]?:u[@"input_tokens"]);UPut(d,@"output",u[@"completion_tokens"]?:u[@"output_tokens"]);
  UPut(d,@"cachedInput",UDict(u[@"prompt_tokens_details"])[@"cached_tokens"]?:UDict(u[@"input_tokens_details"])[@"cached_tokens"]?:u[@"prompt_cache_hit_tokens"]);
  UPut(d,@"reasoning",UDict(u[@"completion_tokens_details"])[@"reasoning_tokens"]?:UDict(u[@"output_tokens_details"])[@"reasoning_tokens"]);UPut(d,@"providerTotal",u[@"total_tokens"]);
  if(!d[@"input"]&&UCount(u[@"prompt_cache_hit_tokens"])&&UCount(u[@"prompt_cache_miss_tokens"]))d[@"input"]=@([u[@"prompt_cache_hit_tokens"] unsignedLongLongValue]+[u[@"prompt_cache_miss_tokens"] unsignedLongLongValue]);
 }
 return d;
}
static NSDictionary *UDerived(NSDictionary *record){
 NSMutableDictionary *r=[record mutableCopy];NSMutableDictionary *c=[UDict(r[@"counts"]) mutableCopy];NSString *wire=r[@"wire"];
 if([wire isEqual:@"anthropic"]&&c[@"uncachedInput"])c[@"input"]=@([c[@"uncachedInput"] unsignedLongLongValue]+[c[@"cachedInput"] unsignedLongLongValue]+[c[@"cacheWrite"] unsignedLongLongValue]);
 if([wire isEqual:@"gemini"]&&c[@"promptInput"])c[@"input"]=@([c[@"promptInput"] unsignedLongLongValue]+[c[@"toolInput"] unsignedLongLongValue]);
 // Gemini reports candidate output and thought output separately.
 if([wire isEqual:@"gemini"]&&c[@"visibleOutput"])c[@"output"]=@([c[@"visibleOutput"] unsignedLongLongValue]+[c[@"reasoning"] unsignedLongLongValue]);
 if(c[@"providerTotal"])c[@"total"]=c[@"providerTotal"];else if(c[@"input"]&&c[@"output"])c[@"total"]=@([c[@"input"] unsignedLongLongValue]+[c[@"output"] unsignedLongLongValue]);
 if(c[@"cachedInput"]&&c[@"input"]&&[c[@"cachedInput"] unsignedLongLongValue]>[c[@"input"] unsignedLongLongValue]){[c removeObjectForKey:@"cachedInput"];r[@"invalidCache"]=@YES;}
 r[@"counts"]=c;return r;
}
NSDictionary *TFAIUsageTotals(NSArray *records){
 NSMutableDictionary *totals=[NSMutableDictionary new];NSMutableSet *sessions=[NSMutableSet new];NSUInteger reported=0,complete=0,cacheKnown=0;unsigned long long cacheDenominator=0;
 for(NSDictionary *raw in records){NSDictionary *r=UDerived(raw),*c=r[@"counts"];if(c.count)reported++;if(c[@"input"]&&c[@"output"])complete++;
  for(NSString *k in @[@"input",@"output",@"total",@"cachedInput",@"cacheWrite",@"reasoning"])if(c[k])totals[k]=@([totals[k] unsignedLongLongValue]+[c[k] unsignedLongLongValue]);
  if(c[@"input"]&&c[@"cachedInput"]){cacheKnown++;cacheDenominator+=[c[@"input"] unsignedLongLongValue];}
  [sessions addObject:@[r[@"project"]?:@"",r[@"session"]?:@""]];
 }
 totals[@"requests"]=@(records.count);totals[@"reported"]=@(reported);totals[@"complete"]=@(complete);totals[@"sessions"]=@(sessions.count);totals[@"cacheKnown"]=@(cacheKnown);totals[@"cacheDenominator"]=@(cacheDenominator);
 // Do not use cache counters from requests with no known input denominator.
 unsigned long long hits=0;for(NSDictionary *raw in records){NSDictionary *c=UDerived(raw)[@"counts"];if(c[@"input"]&&c[@"cachedInput"])hits+=[c[@"cachedInput"] unsignedLongLongValue];}if(cacheDenominator)totals[@"cacheHitRate"]=@((double)hits/(double)cacheDenominator);
 return totals;
}
@interface TFAIUsageStore ()
@property NSURL *directory;
@property dispatch_queue_t queue;
@property NSMutableDictionary *active;
@property NSString *writeError;
@end
@implementation TFAIUsageStore
+ (instancetype)shared{static TFAIUsageStore *s;static dispatch_once_t once;dispatch_once(&once,^{NSURL *library=[NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;NSURL *directory=[library URLByAppendingPathComponent:@"Dylix/AIUsage-v1" isDirectory:YES];
#if !TARGET_OS_IPHONE
 NSString *fixture=NSProcessInfo.processInfo.environment[@"DYLIX_USAGE_TEST_DIRECTORY"];if(fixture.length)directory=[NSURL fileURLWithPath:fixture isDirectory:YES];
#endif
 s=[[self alloc]initWithDirectory:directory];});return s;}
- (instancetype)initWithDirectory:(NSURL *)directory{if((self=[super init])){_directory=directory;_queue=dispatch_queue_create("app.dylix.usage",DISPATCH_QUEUE_SERIAL);_active=[NSMutableDictionary new];}return self;}
- (NSURL *)file:(NSString *)identifier{if(![identifier isKindOfClass:NSString.class]||![[NSUUID alloc]initWithUUIDString:identifier])return nil;return [self.directory URLByAppendingPathComponent:[identifier stringByAppendingPathExtension:@"json"]];}
- (void)persist:(NSDictionary *)r{NSURL *url=[self file:r[@"id"]];if(!url)return;NSError *e=nil;[NSFileManager.defaultManager createDirectoryAtURL:self.directory withIntermediateDirectories:YES attributes:nil error:&e];NSData *data=e?nil:[NSJSONSerialization dataWithJSONObject:r options:0 error:&e];if(data)[data writeToURL:url options:NSDataWritingAtomic error:&e];self.writeError=e?@"用量记录未能写入本机存储，请检查可用空间。":nil;}
- (void)begin:(NSString *)identifier project:(NSString *)project session:(NSString *)session connection:(NSDictionary *)connection wire:(NSString *)wire{
 if(![self file:identifier])return;NSMutableDictionary *r=[@{@"id":identifier,@"project":project?:@"general",@"session":session?:@"",@"wire":wire?:@"chat",@"startedAt":@(NSDate.date.timeIntervalSince1970),@"status":@"running",@"counts":@{}} mutableCopy];
 for(NSString *k in @[@"id",@"name",@"protocol",@"model"])if([connection[k] isKindOfClass:NSString.class])r[[@"connection_" stringByAppendingString:k]]=[connection[k] substringToIndex:MIN(512,[connection[k] length])];
 dispatch_async(self.queue,^{if(self.active[identifier]||[NSFileManager.defaultManager fileExistsAtPath:[self file:identifier].path])return;self.active[identifier]=r;[self persist:r];});
}
- (void)update:(NSString *)identifier usage:(NSDictionary *)usage{NSDictionary *snapshot=[usage copy];dispatch_async(self.queue,^{NSMutableDictionary *r=self.active[identifier];if(!r)return;NSMutableDictionary *c=[r[@"counts"] mutableCopy];NSDictionary *delta=TFAINormalizeUsage(snapshot,r[@"wire"]);for(NSString *k in delta)c[k]=@(MAX([c[k] unsignedLongLongValue],[delta[k] unsignedLongLongValue]));r[@"counts"]=c;[self persist:r];});}
- (void)finish:(NSString *)identifier status:(NSString *)status{if(!identifier.length)return;dispatch_async(self.queue,^{NSMutableDictionary *r=self.active[identifier];if(!r)return;r[@"status"]=[@[@"completed",@"failed",@"stopped"] containsObject:status]?status:@"interrupted";r[@"finishedAt"]=@(NSDate.date.timeIntervalSince1970);[self persist:r];[self.active removeObjectForKey:identifier];});}
- (void)read:(void (^)(NSArray<NSDictionary *> *,NSString * _Nullable))completion{dispatch_async(self.queue,^{NSMutableArray *records=[NSMutableArray new];NSError *error=nil;NSArray *urls=[NSFileManager.defaultManager contentsOfDirectoryAtURL:self.directory includingPropertiesForKeys:@[NSURLFileSizeKey] options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];NSUInteger damaged=0;for(NSURL *url in urls){if(![url.pathExtension isEqual:@"json"])continue;NSNumber *size=nil;[url getResourceValue:&size forKey:NSURLFileSizeKey error:nil];if(size.unsignedLongLongValue>16384){damaged++;continue;}NSData *data=[NSData dataWithContentsOfURL:url];id object=data?[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]:nil;
  if(![object isKindOfClass:NSDictionary.class]||![[self file:object[@"id"]].lastPathComponent isEqual:url.lastPathComponent]||![object[@"startedAt"] isKindOfClass:NSNumber.class]||![object[@"counts"] isKindOfClass:NSDictionary.class]){damaged++;continue;}
  NSMutableDictionary *r=[object mutableCopy];NSMutableDictionary *safe=[NSMutableDictionary new];for(NSString *key in @[@"input",@"output",@"cachedInput",@"cacheWrite",@"uncachedInput",@"reasoning",@"visibleOutput",@"providerTotal",@"promptInput",@"toolInput"])UPut(safe,key,object[@"counts"][key]);r[@"counts"]=safe;for(NSString *key in @[@"project",@"session",@"wire",@"status",@"connection_id",@"connection_name",@"connection_protocol",@"connection_model"])if(![r[key] isKindOfClass:NSString.class])r[key]=@"";if([r[@"status"] isEqual:@"running"]&&!self.active[r[@"id"]])r[@"status"]=@"interrupted";[records addObject:UDerived(r)];}
 [records sortUsingComparator:^NSComparisonResult(NSDictionary *a,NSDictionary *b){return [b[@"startedAt"] compare:a[@"startedAt"]];}];NSString *message=self.writeError;if(error&&error.code!=NSFileReadNoSuchFileError)message=DXLoc(@"无法读取用量记录。");if(damaged)message=[NSString stringWithFormat:DXLoc(@"已跳过 %lu 条损坏记录。%@"),(unsigned long)damaged,message?:@""];completion(records,message);});}
@end
