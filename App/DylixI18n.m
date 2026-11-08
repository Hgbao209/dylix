#import "DylixI18n.h"

static NSString *const kDylixLanguageKey = @"DylixAppLanguage";

@interface DylixI18n ()
@property (nonatomic, strong) NSBundle *currentBundle;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *viFallbackDict;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *enFallbackDict;
@end

@implementation DylixI18n

+ (instancetype)shared {
    static DylixI18n *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DylixI18n alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupFallbackDictionaries];
        NSString *saved = [[NSUserDefaults standardUserDefaults] stringForKey:kDylixLanguageKey];
        if (!saved) {
            saved = @"system";
        }
        [self setLanguage:saved];
    }
    return self;
}

- (void)setupFallbackDictionaries {
    // Built-in Vietnamese dictionary ensuring basic translations always resolve
    self.viFallbackDict = @{
        @"项目": @"Dự án",
        @"AI 会话": @"Trò chuyện AI",
        @"设置": @"Cài đặt",
        @"工程操作": @"Thao tác dự án",
        @"新建文件": @"Tạo tệp mới",
        @"重命名当前文件": @"Đổi tên tệp hiện tại",
        @"项目设置": @"Cài đặt dự án",
        @"构建诊断": @"Chẩn đoán bản dựng",
        @"查找与替换": @"Tìm & Thay thế",
        @"分享当前源码": @"Chia sẻ mã nguồn hiện tại",
        @"分享构建结果": @"Chia sẻ kết quả dựng",
        @"AI 开发助手": @"Trợ lý AI",
        @"源代码管理 Git": @"Quản lý Git",
        @"取消": @"Hủy",
        @"确定": @"Xác nhận",
        @"确认": @"Xác nhận",
        @"编辑": @"Chỉnh sửa",
        @"删除": @"Xóa",
        @"保存": @"Lưu",
        @"刷新": @"Làm mới",
        @"复制": @"Sao chép",
        @"完成": @"Hoàn tất",
        @"关闭": @"Đóng",
        @"返回": @"Quay lại",
        @"正在构建": @"Đang xây dựng...",
        @"构建结果": @"Kết quả xây dựng",
        @"构建通过 · 运行待验证": @"Xây dựng thành công · Chờ kiểm tra",
        @"构建失败，请查看日志和报告": @"Xây dựng thất bại, vui lòng kiểm tra nhật ký",
        @"暂无构建结果": @"Chưa có kết quả dựng",
        @"本次构建": @"Lần dựng này",
        @"产物与构建记录": @"Sản phẩm và nhật ký dựng",
        @"开始时间": @"Thời gian bắt đầu",
        @"完成时间": @"Thời gian hoàn thành",
        @"构建耗时": @"Thời gian dựng",
        @"文件合计": @"Tổng số tệp",
        @"源代码管理": @"Quản lý mã nguồn",
        @"AI": @"Trí tuệ nhân tạo (AI)",
        @"远程开发": @"Phát triển từ xa",
        @"工具": @"Công cụ",
        @"外观与编辑器": @"Giao diện & Trình biên tập",
        @"构建与产物": @"Bản dựng & Sản phẩm đầu ra",
        @"工具链与本机": @"Chuỗi công cụ & Thiết bị",
        @"关于": @"Giới thiệu",
        @"局域网远程": @"Điều khiển qua LAN",
        @"Dylix Remote · 浏览器工作台": @"Dylix Remote · Bàn làm việc trình duyệt",
        @"项目开源地址": @"Kho mã nguồn mở",
        @"软件许可证": @"Giấy phép phần mềm",
        @"人设": @"Nhân vật / Persona",
        @"界面外观": @"Giao diện",
        @"代码字号": @"Cỡ chữ mã nguồn",
        @"自动保存": @"Tự động lưu",
        @"语言": @"Ngôn ngữ",
        @"跟随系统": @"Theo hệ thống",
        @"石墨深色": @"Tối than chì",
        @"纸感浅色": @"Sáng giấy tự nhiên",
        @"始终开启": @"Luôn bật",
        @"优化方案": @"Phương án tối ưu hóa",
        @"目标架构": @"Kiến trúc mục tiêu",
        @"默认构建设置": @"Cài đặt dựng mặc định",
        @"存储空间": @"Dung lượng lưu trữ",
        @"IPA 头文件导出": @"Xuất Header IPA",
        @"离线崩溃分析": @"Phân tích sự cố ngoại tuyến",
        @"关于 Dylix": @"Về Dylix",
        @"版本": @"Phiên bản",
        @"作者": @"Tác giả",
        @"本机工具链": @"Chuỗi công cụ trên máy",
        @"功能与使用": @"Tính năng & Hướng dẫn",
        @"诊断与适配": @"Chẩn đoán & Tương thích",
        @"开源组件与许可证": @"Thành phần mã nguồn mở",
        @"软件功能说明": @"Mô tả tính năng phần mềm",
        @"编译与使用说明": @"Hướng dẫn biên dịch & sử dụng",
        @"隐私与本地存储": @"Quyền riêng tư & Lưu trữ cục bộ",
        @"编译诊断与兼容适配规则库": @"Quy tắc chẩn đoán & tương thích",
        @"适配前后诊断记录": @"Lịch sử chẩn đoán trước/sau sửa lỗi",
        @"导入 .ips / 符号档案": @"Nhập tệp .ips / Ký hiệu",
        @"选择偏好": @"Chọn tùy chọn",
        @"跟随全局": @"Theo cài đặt chung",
        @"默认均衡 · -O2": @"Cân bằng mặc định · -O2",
        @"体积优先 · -Os": @"Ưu tiên kích thước nhỏ · -Os",
        @"调试排错 · -O0": @"Gỡ lỗi Debug · -O0",
        @"基础优化 · -O1": @"Tối ưu hóa cơ bản · -O1",
        @"激进优化 · -O3": @"Tối ưu hóa nâng cao · -O3",
        @"极限体积 · -Oz": @"Kích thước tối thiểu · -Oz",
        @"自动裁剪 · 推荐": @"Tự động cắt tỉa ký hiệu · Khuyên dùng",
        @"保留完整符号": @"Giữ nguyên ký hiệu đầy đủ",
        @"常用方案": @"Phương án phổ biến",
        @"符号处理": @"Xử lý ký hiệu",
        @"高级选项": @"Tùy chọn nâng cao"
    };

    self.enFallbackDict = @{
        @"项目": @"Projects",
        @"AI 会话": @"AI Chat",
        @"设置": @"Settings",
        @"工程操作": @"Project Actions",
        @"新建文件": @"New File",
        @"重命名当前文件": @"Rename File",
        @"项目设置": @"Project Settings",
        @"构建诊断": @"Build Diagnostics",
        @"查找与替换": @"Find & Replace",
        @"分享当前源码": @"Share Source Code",
        @"分享构建结果": @"Share Build Results",
        @"AI 开发助手": @"AI Assistant",
        @"源代码管理 Git": @"Git Source Control",
        @"取消": @"Cancel",
        @"确定": @"OK",
        @"确认": @"Confirm",
        @"编辑": @"Edit",
        @"删除": @"Delete",
        @"保存": @"Save",
        @"刷新": @"Refresh",
        @"复制": @"Copy",
        @"完成": @"Done",
        @"关闭": @"Close",
        @"返回": @"Back",
        @"正在构建": @"Building...",
        @"构建结果": @"Build Results",
        @"构建通过 · 运行待验证": @"Build Succeeded · Untested",
        @"构建失败，请查看日志和报告": @"Build Failed, check logs",
        @"暂无构建结果": @"No Build Results",
        @"本次构建": @"Current Build",
        @"产物与构建记录": @"Artifacts & Logs",
        @"开始时间": @"Start Time",
        @"完成时间": @"Finish Time",
        @"构建耗时": @"Build Duration",
        @"文件合计": @"Total Files",
        @"源代码管理": @"Source Control",
        @"AI": @"AI",
        @"远程开发": @"Remote Development",
        @"工具": @"Tools",
        @"外观与编辑器": @"Appearance & Editor",
        @"构建与产物": @"Build & Artifacts",
        @"工具链与本机": @"Toolchain & Device",
        @"关于": @"About",
        @"局域网远程": @"LAN Remote",
        @"Dylix Remote · 浏览器工作台": @"Dylix Remote · Web Workspace",
        @"项目开源地址": @"Open Source Repository",
        @"软件许可证": @"Software License",
        @"人设": @"Persona",
        @"界面外观": @"Appearance",
        @"代码字号": @"Code Font Size",
        @"自动保存": @"Auto Save",
        @"语言": @"Language",
        @"跟随系统": @"Follow System",
        @"石墨深色": @"Graphite Dark",
        @"纸感浅色": @"Paper Light",
        @"始终开启": @"Always On",
        @"优化方案": @"Optimization",
        @"目标架构": @"Target Architecture",
        @"默认构建设置": @"Default Build Settings",
        @"存储空间": @"Storage Space",
        @"IPA 头文件导出": @"IPA Header Export",
        @"离线崩溃分析": @"Offline Crash Analysis",
        @"关于 Dylix": @"About Dylix",
        @"版本": @"Version",
        @"作者": @"Author",
        @"本机工具链": @"Local Toolchain",
        @"功能与使用": @"Features & Usage",
        @"诊断与适配": @"Diagnostics & Compatibility",
        @"开源组件与许可证": @"Open Source Components",
        @"软件功能说明": @"Software Features",
        @"编译与使用说明": @"Build & Usage Guide",
        @"隐私与本地存储": @"Privacy & Local Storage",
        @"编译诊断与兼容适配规则库": @"Build Diagnostics Rules",
        @"适配前后诊断记录": @"Repair History",
        @"导入 .ips / 符号档案": @"Import .ips / Symbols",
        @"选择偏好": @"Preferences",
        @"跟随全局": @"Follow Global",
        @"默认均衡 · -O2": @"Default Balanced · -O2",
        @"体积优先 · -Os": @"Size First · -Os",
        @"调试排错 · -O0": @"Debug · -O0",
        @"基础优化 · -O1": @"Basic · -O1",
        @"激进优化 · -O3": @"Aggressive · -O3",
        @"极限体积 · -Oz": @"Minimum Size · -Oz",
        @"自动裁剪 · 推荐": @"Auto Strip · Recommended",
        @"保留完整符号": @"Keep Full Symbols",
        @"常用方案": @"Common Presets",
        @"符号处理": @"Symbol Policy",
        @"高级选项": @"Advanced Options"
    };
}

- (NSArray<NSDictionary<NSString *, NSString *> *> *)availableLanguages {
    return @[
        @{@"code": @"system", @"name": DXLoc(@"跟随系统")},
        @{@"code": @"vi", @"name": @"Tiếng Việt"},
        @{@"code": @"zh-Hans", @"name": @"简体中文"},
        @{@"code": @"en", @"name": @"English"}
    ];
}

- (NSString *)effectiveLanguageCode {
    if (![self.language isEqualToString:@"system"]) {
        return self.language;
    }
    NSString *preferred = [NSLocale preferredLanguages].firstObject ?: @"zh-Hans";
    if ([preferred hasPrefix:@"vi"]) return @"vi";
    if ([preferred hasPrefix:@"zh"]) return @"zh-Hans";
    if ([preferred hasPrefix:@"en"]) return @"en";
    return @"zh-Hans";
}

- (NSString *)currentLanguageDisplayName {
    if ([self.language isEqualToString:@"system"]) {
        NSString *code = [self effectiveLanguageCode];
        NSString *effName = @"简体中文";
        if ([code isEqualToString:@"vi"]) effName = @"Tiếng Việt";
        else if ([code isEqualToString:@"en"]) effName = @"English";
        return [NSString stringWithFormat:@"%@ (%@)", DXLoc(@"跟随系统"), effName];
    }
    for (NSDictionary *dict in self.availableLanguages) {
        if ([dict[@"code"] isEqualToString:self.language]) {
            return dict[@"name"];
        }
    }
    return self.language;
}

- (void)setLanguage:(NSString *)language {
    _language = [language copy];
    [[NSUserDefaults standardUserDefaults] setObject:_language forKey:kDylixLanguageKey];

    NSString *code = [self effectiveLanguageCode];
    NSString *path = [NSBundle.mainBundle pathForResource:code ofType:@"lproj"];
    if (!path) {
        // Look inside Resources/
        path = [[NSBundle.mainBundle resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.lproj", code]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            path = nil;
        }
    }
    if (path) {
        self.currentBundle = [NSBundle bundleWithPath:path];
    } else {
        self.currentBundle = nil;
    }
}

+ (NSString *)localized:(NSString *)key {
    return [self localized:key value:nil table:nil];
}

+ (NSString *)localized:(NSString *)key value:(nullable NSString *)defaultValue {
    return [self localized:key value:defaultValue table:nil];
}

+ (NSString *)localized:(NSString *)key value:(nullable NSString *)defaultValue table:(nullable NSString *)table {
    if (!key.length) return @"";
    DylixI18n *i18n = [DylixI18n shared];
    NSString *effCode = [i18n effectiveLanguageCode];

    // If Chinese is active, return key directly as keys are in Chinese
    if ([effCode isEqualToString:@"zh-Hans"] || [effCode hasPrefix:@"zh"]) {
        return defaultValue ?: key;
    }

    // Try bundle lookup
    if (i18n.currentBundle) {
        NSString *localized = [i18n.currentBundle localizedStringForKey:key value:nil table:table];
        if (localized && ![localized isEqualToString:key]) {
            return localized;
        }
    }

    // Check fallback dictionaries
    if ([effCode isEqualToString:@"vi"]) {
        NSString *val = i18n.viFallbackDict[key];
        if (val) return val;
    } else if ([effCode isEqualToString:@"en"]) {
        NSString *val = i18n.enFallbackDict[key];
        if (val) return val;
    }

    return defaultValue ?: key;
}

@end
