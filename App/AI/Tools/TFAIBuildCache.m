#import "TFAIBuildCache.h"
#import "../../DylixI18n.h"
#import <CommonCrypto/CommonDigest.h>
static NSArray *Owned(NSString *root,NSString *docs){
 NSString *prefix=[docs stringByAppendingString:@"/"];NSString *owner=[root hasPrefix:prefix]?[root substringFromIndex:prefix.length]:root;
 NSDictionary *value=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[root stringByAppendingPathComponent:@".studio-build-cache.json"]]?:NSData.data options:0 error:nil];
 return [value isKindOfClass:NSDictionary.class]&&[value[@"owner"] isEqual:owner]&&[value[@"items"] isKindOfClass:NSArray.class]?value[@"items"]:@[];
}
static NSString *BuildPath(NSString *docs,id name){
 if(![name isKindOfClass:NSString.class]||![name hasPrefix:@"Build-"]||![[NSUUID alloc]initWithUUIDString:[name substringFromIndex:6]])return nil;
 NSString *path=[docs stringByAppendingPathComponent:name];NSDictionary *attrs=[NSFileManager.defaultManager attributesOfItemAtPath:path error:nil];
 return [attrs[NSFileType] isEqual:NSFileTypeDirectory]&&[path.stringByResolvingSymlinksInPath isEqual:[docs.stringByResolvingSymlinksInPath stringByAppendingPathComponent:name]]?path:nil;
}
NSArray *TFAIProjectBuilds(NSString *root,NSString *docs){
 NSMutableArray *items=[NSMutableArray new];for(id name in Owned(root,docs)){NSString *path=BuildPath(docs,name);if(!path)continue;NSDictionary *attrs=[NSFileManager.defaultManager attributesOfItemAtPath:path error:nil];NSMutableArray *files=[NSMutableArray new];for(NSString *file in [NSFileManager.defaultManager contentsOfDirectoryAtPath:path error:nil])if([@[@"deb",@"dylib"] containsObject:file.pathExtension])[files addObject:file];[items addObject:@{@"buildID":name,@"modified":@([attrs[NSFileModificationDate] timeIntervalSince1970]),@"artifacts":files}];}
 [items sortUsingComparator:^NSComparisonResult(NSDictionary *a,NSDictionary *b){return [b[@"modified"] compare:a[@"modified"]];}];return items;
}
NSDictionary *TFAICleanProjectBuilds(NSString *root,NSString *docs,NSArray *ids,NSError **error){
 NSArray *owned=Owned(root,docs);NSMutableArray *paths=[NSMutableArray new];
 if(!ids.count||ids.count>100){if(error)*error=[NSError errorWithDomain:@"AI.BuildCache" code:1 userInfo:@{NSLocalizedDescriptionKey:DXLoc(@"请指定 1–100 个构建编号，先调用 list_builds")}];return nil;}
 for(id name in ids){NSString *path=BuildPath(docs,name);if(![owned containsObject:name]||!path){if(error)*error=[NSError errorWithDomain:@"AI.BuildCache" code:2 userInfo:@{NSLocalizedDescriptionKey:DXLoc(@"构建不属于当前项目、已移除或路径已变化；未开始清理")}];return nil;}if(![paths containsObject:path])[paths addObject:path];}
 NSMutableArray *deleted=[NSMutableArray new];for(NSString *path in paths){if(![NSFileManager.defaultManager removeItemAtPath:path error:error])return nil;[deleted addObject:path.lastPathComponent];}
 // Keep historical ownership entries: missing outputs are filtered above and other builds remain intact.
 return @{@"deletedBuildIDs":deleted,@"count":@(deleted.count),@"remainingBuilds":TFAIProjectBuilds(root,docs),@"message":DXLoc(@"已清理所选构建结果；项目源码和会话记录保留")};
}
NSString *TFAISessionCheckpointDirectory(NSString *caches,NSString *root,NSString *sessionID){
 if(!root.length||!sessionID.length||!caches.length)return nil;
 NSData *data=[NSJSONSerialization dataWithJSONObject:@[root,sessionID] options:0 error:nil];uint8_t bytes[CC_SHA256_DIGEST_LENGTH];CC_SHA256(data.bytes,(CC_LONG)data.length,bytes);NSMutableString *hash=[NSMutableString new];for(NSUInteger i=0;i<sizeof(bytes);i++)[hash appendFormat:@"%02x",bytes[i]];
 return [[caches stringByAppendingPathComponent:@"DylixSessionBuildCheckpoints"] stringByAppendingPathComponent:hash];
}
NSDictionary *TFAICleanSessionBuildCache(NSString *root,NSString *docs,NSString *sessionID,NSString *caches,NSError **error){
 NSFileManager *fm=NSFileManager.defaultManager;NSMutableArray *paths=[NSMutableArray new];NSString *checkpoint=TFAISessionCheckpointDirectory(caches,root,sessionID);
 if(!checkpoint){if(error)*error=[NSError errorWithDomain:@"AI.BuildCache" code:4 userInfo:@{NSLocalizedDescriptionKey:DXLoc(@"构建会话范围缺失，未开始清理")}];return nil;}
 // Resolve only app-generated locations; never follow a cache/snapshot symlink.
 BOOL (^safe)(NSString *,NSString *)=^BOOL(NSString *path,NSString *parent){return [path.stringByResolvingSymlinksInPath isEqual:[parent.stringByResolvingSymlinksInPath stringByAppendingPathComponent:path.lastPathComponent]]&&[[fm attributesOfItemAtPath:path error:nil][NSFileType] isEqual:NSFileTypeDirectory];};
 NSString *checkpointParent=checkpoint.stringByDeletingLastPathComponent;
 NSDictionary *parentAttrs=[fm attributesOfItemAtPath:checkpointParent error:nil];
 if(parentAttrs&&(!safe(checkpointParent,caches)||([fm attributesOfItemAtPath:checkpoint error:nil]&&!safe(checkpoint,checkpointParent)))){if(error)*error=[NSError errorWithDomain:@"AI.BuildCache" code:5 userInfo:@{NSLocalizedDescriptionKey:DXLoc(@"会话缓存路径发生变化，未开始清理")}];return nil;}
 if([fm fileExistsAtPath:checkpoint])[paths addObject:checkpoint];
 NSString *owner=[root hasPrefix:[docs stringByAppendingString:@"/"]]?[root substringFromIndex:docs.length+1]:root;
 for(id name in Owned(root,docs)){
  NSString *build=BuildPath(docs,name);if(!build)continue;
  NSString *marker=[build stringByAppendingPathComponent:@".studio-cache-owner.json"];NSDictionary *markerAttrs=[fm attributesOfItemAtPath:marker error:nil];if(![markerAttrs[NSFileType] isEqual:NSFileTypeRegular])continue;
  id meta=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:marker]?:NSData.data options:0 error:nil];
  if(![meta isKindOfClass:NSDictionary.class]||![meta[@"sessionID"] isEqual:sessionID]||!([meta[@"project"] isEqual:root]||[meta[@"projectKey"] isEqual:owner]))continue;
  // An unfinished build may still be using its inputs. Leave it untouched.
  if(![fm fileExistsAtPath:[build stringByAppendingPathComponent:@"report.json"]])continue;
  for(NSString *item in [fm contentsOfDirectoryAtPath:build error:nil]){
   BOOL generated=([item hasPrefix:@"source-"]&&[item.pathExtension isEqual:@"o"])||([item hasPrefix:@"logos-"]&&[@[@"m",@"mm"] containsObject:item.pathExtension])||[item isEqual:@".package-link-cache"];
   if(!generated)continue;NSString *path=[build stringByAppendingPathComponent:item];NSDictionary *attrs=[fm attributesOfItemAtPath:path error:nil];
   if([attrs[NSFileType] isEqual:NSFileTypeSymbolicLink]||![path.stringByResolvingSymlinksInPath hasPrefix:[build.stringByResolvingSymlinksInPath stringByAppendingString:@"/"]]){if(error)*error=[NSError errorWithDomain:@"AI.BuildCache" code:5 userInfo:@{NSLocalizedDescriptionKey:DXLoc(@"构建中间文件路径发生变化，未开始清理")}];return nil;}[paths addObject:path];
  }
  NSString *snapshot=meta[@"snapshot"];NSString *snapshotName=[snapshot isKindOfClass:NSString.class]?snapshot.lastPathComponent:nil;
  if([snapshotName hasPrefix:@"Snapshot-"]&&[[NSUUID alloc]initWithUUIDString:[snapshotName substringFromIndex:9]]&&[snapshot.stringByDeletingLastPathComponent isEqual:docs]&&[fm fileExistsAtPath:snapshot]){
   if(!safe(snapshot,docs)){if(error)*error=[NSError errorWithDomain:@"AI.BuildCache" code:5 userInfo:@{NSLocalizedDescriptionKey:DXLoc(@"会话快照路径发生变化，未开始清理")}];return nil;}[paths addObject:snapshot];
  }
 }
 NSMutableArray *removed=[NSMutableArray new];for(NSString *path in [NSOrderedSet orderedSetWithArray:paths]){if(![fm removeItemAtPath:path error:error])return nil;[removed addObject:path.lastPathComponent];}
 return @{@"scope":@"current_project_current_session",@"sessionID":sessionID,@"removed":removed,@"count":@(removed.count),@"artifactsPreserved":@YES};
}
