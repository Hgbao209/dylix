#import <Foundation/Foundation.h>
#import "DylixI18n.h"
#import <mach-o/loader.h>

// Native RootHide linkage follows roothide/Developer; this is not a rootless
// package conversion and does not claim compatibility with arbitrary resources.
static NSArray *TMCPackageLinkArguments(NSArray *original, NSString *scheme, NSString *frameworks, NSString *product) {
    NSMutableArray *args = [original mutableCopy];
    NSString *native = [frameworks stringByAppendingPathComponent:@"roothide"];
    for (NSInteger i = (NSInteger)args.count - 2; i >= 0; i--) {
        if (([args[i] isEqual:@"-F"] || [args[i] isEqual:@"-L"]) && [args[i+1] isEqual:native]) {
            [args removeObjectsInRange:NSMakeRange(i, 2)];
        }
    }
    BOOL hidden = [scheme isEqual:@"roothide"];
    if (hidden) {
        NSUInteger at = [args indexOfObject:@"-F"];
        if (at == NSNotFound) at = [args indexOfObject:@"-adhoc_codesign"];
        if (at == NSNotFound) at = args.count;
        [args insertObjects:@[@"-F", native, @"-L", native] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(at, 4)]];
    }
    // All schemes and standalone dylibs need a code signature, not only RootHide.
    [args removeObject:@"-no_adhoc_codesign"];
    if (![args containsObject:@"-adhoc_codesign"]) [args addObject:@"-adhoc_codesign"];
    NSString *rpath = hidden ? @"@loader_path/.jbroot/Library/Frameworks" : [scheme isEqual:@"rootless"] ? @"/var/jb/Library/Frameworks" : @"/Library/Frameworks";
    NSUInteger index = [args indexOfObject:@"-rpath"];
    if (index != NSNotFound && index + 1 < args.count) args[index+1] = rpath;
    index = [args indexOfObject:@"-install_name"];
    if (index != NSNotFound && index + 1 < args.count) args[index+1] = [NSString stringWithFormat:hidden ? @"@loader_path/.jbroot/Library/MobileSubstrate/DynamicLibraries/%@.dylib" : @"@rpath/%@.dylib", product];
    return args;
}

static BOOL TMCNativeRootHideImage(NSData *data, NSError **error) {
    NSString *(^problem)(void) = ^NSString *{
        if (data.length < sizeof(struct mach_header_64)) return DXLoc(@"隐根产物不是完整的 Mach-O");
        struct mach_header_64 h; memcpy(&h, data.bytes, sizeof(h));
        if (h.magic != MH_MAGIC_64 || h.filetype != MH_DYLIB || h.cputype != CPU_TYPE_ARM64 || h.sizeofcmds > data.length - sizeof(h) || h.ncmds > h.sizeofcmds / 8) return DXLoc(@"隐根产物的 Mach-O 头无效");
        NSUInteger offset = sizeof(h), end = offset + h.sizeofcmds;
        BOOL signedImage = NO, nativeID = NO;
        for (NSUInteger i = 0; i < h.ncmds; i++) {
            struct load_command c;
            if (offset > end || end - offset < sizeof(c)) return DXLoc(@"隐根加载命令被截断");
            memcpy(&c, (const char *)data.bytes + offset, sizeof(c));
            if (c.cmdsize < 8 || c.cmdsize > end - offset) return DXLoc(@"隐根加载命令长度无效");
            if (c.cmd == LC_CODE_SIGNATURE) {
                if (c.cmdsize < sizeof(struct linkedit_data_command)) return DXLoc(@"隐根签名记录无效");
                struct linkedit_data_command sig; memcpy(&sig, (const char *)data.bytes + offset, sizeof(sig));
                signedImage = sig.datasize >= 12 && sig.dataoff >= end && sig.dataoff <= data.length && sig.datasize <= data.length - sig.dataoff;
            }
            BOOL dylib = c.cmd == LC_ID_DYLIB || c.cmd == LC_LOAD_DYLIB || c.cmd == LC_LOAD_WEAK_DYLIB || c.cmd == LC_REEXPORT_DYLIB || c.cmd == LC_LOAD_UPWARD_DYLIB;
            if (dylib || c.cmd == LC_RPATH) {
                uint32_t start = 0;
                NSUInteger minimum = dylib ? sizeof(struct dylib_command) : sizeof(struct rpath_command);
                if (c.cmdsize < minimum) return DXLoc(@"隐根加载路径记录无效");
                memcpy(&start, (const char *)data.bytes + offset + 8, sizeof(start));
                if (start < minimum || start >= c.cmdsize) return DXLoc(@"隐根加载路径偏移无效");
                const char *p = (const char *)data.bytes + offset + start;
                const char *nul = memchr(p, 0, c.cmdsize - start);
                if (!nul) return DXLoc(@"隐根加载路径未终止");
                NSString *path = [[NSString alloc] initWithBytes:p length:(NSUInteger)(nul-p) encoding:NSUTF8StringEncoding];
                if (!path) return DXLoc(@"隐根加载路径不是 UTF-8");
                if ([path containsString:@"/var/jb/"] || [path isEqual:@"/var/jb"]) return DXLoc(@"隐根产物仍引用 /var/jb，请使用隐根版本的第三方库");
                if ([path isEqual:@"@rpath/CydiaSubstrate.framework/CydiaSubstrate"] || [path isEqual:@"/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate"] || [path isEqual:@"/usr/lib/libsubstrate.dylib"]) return DXLoc(@"隐根 Substrate 链接路径未适配");
                if (c.cmd == LC_ID_DYLIB) nativeID = [path hasPrefix:@"@loader_path/.jbroot/"];
            }
            offset += c.cmdsize;
        }
        if (offset != end) return DXLoc(@"隐根加载命令数量不一致");
        if (!nativeID) return DXLoc(@"隐根 install_name 未适配");
        if (!signedImage) return DXLoc(@"隐根产物缺少 ad-hoc 签名");
        return nil;
    };
    NSString *message = problem();
    if (message && error) *error = [NSError errorWithDomain:@"Compiler" code:8 userInfo:@{NSLocalizedDescriptionKey:message}];
    return message == nil;
}
