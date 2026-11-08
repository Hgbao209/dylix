#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DylixI18n : NSObject

+ (instancetype)shared;

+ (NSString *)localized:(NSString *)key;
+ (NSString *)localized:(NSString *)key value:(nullable NSString *)defaultValue;
+ (NSString *)localized:(NSString *)key value:(nullable NSString *)defaultValue table:(nullable NSString *)table;

@property (nonatomic, copy) NSString *language; // @"system", @"vi", @"zh-Hans", @"en"
@property (nonatomic, readonly) NSString *currentLanguageDisplayName;
@property (nonatomic, readonly) NSArray<NSDictionary<NSString *, NSString *> *> *availableLanguages;

- (void)setLanguage:(NSString *)language;

@end

#define DXLoc(key) [DylixI18n localized:(key)]
#define DXLocVal(key, val) [DylixI18n localized:(key) value:(val)]
#define DXLocFmt(key, ...) [NSString stringWithFormat:[DylixI18n localized:(key)], ##__VA_ARGS__]

NS_ASSUME_NONNULL_END
