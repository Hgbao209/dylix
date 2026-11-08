#import "DXRemoteTLS.h"
#import "../DylixI18n.h"
#import <CommonCrypto/CommonDigest.h>
#import <arpa/inet.h>
// Exported since iOS 11.2; declared in the iOS 26 public header. Keep Xcode 16
// simulator compilation consistent with the same runtime API.
extern SecIdentityRef _Nullable SecIdentityCreate(CFAllocatorRef _Nullable allocator,SecCertificateRef certificate,SecKeyRef key) CF_RETURNS_RETAINED;
static NSError *TLSError(NSInteger code){return [NSError errorWithDomain:@"Dylix.Remote.TLS" code:code userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:DXLoc(@"本机 TLS 身份准备失败（%ld），请检查签名与钥匙串权限"),(long)code]}];}
static NSData *DER(uint8_t tag,NSData *body){NSMutableData *d=[NSMutableData dataWithBytes:&tag length:1];NSUInteger n=body.length;if(n<128){uint8_t b=n;[d appendBytes:&b length:1];}else{uint8_t bytes[sizeof(NSUInteger)],length=0;for(NSUInteger v=n;v;v>>=8)bytes[sizeof(bytes)-1-length++]=v&255;uint8_t b=0x80|length;[d appendBytes:&b length:1];[d appendBytes:bytes+sizeof(bytes)-length length:length];}[d appendData:body];return d;}
static NSData *Join(NSArray<NSData *> *parts){NSMutableData *d=[NSMutableData new];for(NSData *p in parts)[d appendData:p];return d;}
static NSData *Hex(NSString *s){NSMutableData *d=[NSMutableData new];for(NSUInteger i=0;i+1<s.length;i+=2){unsigned v=0;[[NSScanner scannerWithString:[s substringWithRange:NSMakeRange(i,2)]] scanHexInt:&v];uint8_t b=v;[d appendBytes:&b length:1];}return d;}
static NSData *Seq(NSArray *a){return DER(0x30,Join(a));}
static NSData *OID(NSString *hex){return DER(0x06,Hex(hex));}
static NSData *Bits(NSData *data){return DER(0x03,Join(@[Hex(@"00"),data]));}
static NSData *Name(void){return Seq(@[DER(0x31,Seq(@[OID(@"550403"),DER(0x0c,[@"Dylix Remote" dataUsingEncoding:NSUTF8StringEncoding])]))]);}
static NSData *Time(NSDate *date){NSDateFormatter *f=[NSDateFormatter new];f.locale=[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];f.timeZone=[NSTimeZone timeZoneForSecondsFromGMT:0];f.dateFormat=@"yyMMddHHmmss'Z'";return DER(0x17,[[f stringFromDate:date] dataUsingEncoding:NSASCIIStringEncoding]);}
NSData *DXRemoteCreateCertificate(SecKeyRef key,NSString *address,NSError **error){
 struct in_addr ip;if(inet_pton(AF_INET,address.UTF8String,&ip)!=1){if(error)*error=TLSError(-1);return nil;}
 SecKeyRef pub=SecKeyCopyPublicKey(key);CFErrorRef e=NULL;NSData *point=pub?CFBridgingRelease(SecKeyCopyExternalRepresentation(pub,&e)):nil;if(pub)CFRelease(pub);
 if(!point){if(error)*error=e?CFBridgingRelease(e):TLSError(-2);return nil;}
 uint8_t serial[16];if(SecRandomCopyBytes(kSecRandomDefault,sizeof(serial),serial)!=errSecSuccess){if(error)*error=TLSError(-3);return nil;}serial[0]&=0x7f;serial[0]|=1;
 NSData *algorithm=Seq(@[OID(@"2a8648ce3d040302")]); // ecdsa-with-SHA256
 NSData *spki=Seq(@[Seq(@[OID(@"2a8648ce3d0201"),OID(@"2a8648ce3d030107")]),Bits(point)]);
 NSData *extensions=DER(0xa3,Seq(@[
  Seq(@[OID(@"551d13"),DER(0x01,Hex(@"ff")),DER(0x04,Seq(@[]))]), // CA=false
  Seq(@[OID(@"551d0f"),DER(0x01,Hex(@"ff")),DER(0x04,DER(0x03,Hex(@"0780")))]), // digitalSignature
  Seq(@[OID(@"551d25"),DER(0x04,Seq(@[OID(@"2b06010505070301")]))]), // serverAuth
  Seq(@[OID(@"551d11"),DER(0x04,Seq(@[DER(0x87,[NSData dataWithBytes:&ip length:4])]))])
 ]));
 NSData *tbs=Seq(@[DER(0xa0,DER(0x02,Hex(@"02"))),DER(0x02,[NSData dataWithBytes:serial length:sizeof(serial)]),algorithm,Name(),Seq(@[Time([NSDate dateWithTimeIntervalSinceNow:-300]),Time([NSDate dateWithTimeIntervalSinceNow:90*86400])]),Name(),spki,extensions]);
 NSData *signature=CFBridgingRelease(SecKeyCreateSignature(key,kSecKeyAlgorithmECDSASignatureMessageX962SHA256,(__bridge CFDataRef)tbs,&e));if(!signature){if(error)*error=e?CFBridgingRelease(e):TLSError(-4);return nil;}return Seq(@[tbs,algorithm,Bits(signature)]);
}
static NSMutableDictionary *SecretQuery(NSString *account){return [@{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,(__bridge id)kSecAttrService:@"Dylix.Remote.LocalSecrets.v1",(__bridge id)kSecAttrAccount:account} mutableCopy];}
BOOL DXRemoteSetSecret(NSString *account,NSString *value,NSError **error){NSMutableDictionary *q=SecretQuery(account);OSStatus status;if(value.length){NSDictionary *attrs=@{(__bridge id)kSecValueData:[value dataUsingEncoding:NSUTF8StringEncoding],(__bridge id)kSecAttrAccessible:(__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly};status=SecItemUpdate((__bridge CFDictionaryRef)q,(__bridge CFDictionaryRef)attrs);if(status==errSecItemNotFound){[q addEntriesFromDictionary:attrs];status=SecItemAdd((__bridge CFDictionaryRef)q,NULL);}}else{status=SecItemDelete((__bridge CFDictionaryRef)q);if(status==errSecItemNotFound)status=errSecSuccess;}if(status!=errSecSuccess&&error)*error=TLSError(status);return status==errSecSuccess;}
NSString *DXRemoteGetSecret(NSString *account){NSMutableDictionary *q=SecretQuery(account);q[(__bridge id)kSecReturnData]=@YES;CFTypeRef data=NULL;OSStatus s=SecItemCopyMatching((__bridge CFDictionaryRef)q,&data);if(s!=errSecSuccess)return nil;return [[NSString alloc]initWithData:CFBridgingRelease(data) encoding:NSUTF8StringEncoding];}
@interface DXRemoteTLS ()
@property NSString *directory,*keyTag,*fingerprint;
@property NSData *certificate;
@property SecIdentityRef identity;
@end
@implementation DXRemoteTLS
- (instancetype)initWithDirectory:(NSString *)directory keyTag:(NSString *)tag{if((self=[super init])){_directory=directory;_keyTag=tag;_certificate=NSData.data;_fingerprint=@"";}return self;}
- (void)dealloc{if(_identity)CFRelease(_identity);}
- (BOOL)prepareAddress:(NSString *)address error:(NSError **)error{
 NSData *tag=[self.keyTag dataUsingEncoding:NSUTF8StringEncoding];NSDictionary *query=@{(__bridge id)kSecClass:(__bridge id)kSecClassKey,(__bridge id)kSecAttrApplicationTag:tag,(__bridge id)kSecAttrKeyType:(__bridge id)kSecAttrKeyTypeECSECPrimeRandom,(__bridge id)kSecReturnRef:@YES};CFTypeRef reference=NULL;OSStatus status=SecItemCopyMatching((__bridge CFDictionaryRef)query,&reference);SecKeyRef key=(SecKeyRef)reference;
 if(status!=errSecSuccess&&status!=errSecItemNotFound){if(error)*error=TLSError(status);return NO;}
 if(!key){CFErrorRef e=NULL;NSDictionary *attrs=@{(__bridge id)kSecAttrKeyType:(__bridge id)kSecAttrKeyTypeECSECPrimeRandom,(__bridge id)kSecAttrKeySizeInBits:@256,(__bridge id)kSecPrivateKeyAttrs:@{(__bridge id)kSecAttrIsPermanent:@YES,(__bridge id)kSecAttrApplicationTag:tag,(__bridge id)kSecAttrAccessible:(__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly}};key=SecKeyCreateRandomKey((__bridge CFDictionaryRef)attrs,&e);if(!key){if(error)*error=e?CFBridgingRelease(e):TLSError(-5);return NO;}}
 NSString *path=[self.directory stringByAppendingPathComponent:@"certificate.json"];NSDictionary *old=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:path]?:NSData.data options:0 error:nil];NSData *der=nil;
 if([old[@"address"] isEqual:address]&&[old[@"renewAt"] doubleValue]>NSDate.date.timeIntervalSince1970&&[old[@"der"] isKindOfClass:NSString.class])der=[[NSData alloc]initWithBase64EncodedString:old[@"der"] options:0];
 SecCertificateRef cert=der?SecCertificateCreateWithData(NULL,(__bridge CFDataRef)der):NULL;SecIdentityRef identity=cert?SecIdentityCreate(NULL,cert,key):NULL;
 if(!identity){if(cert)CFRelease(cert);der=DXRemoteCreateCertificate(key,address,error);cert=der?SecCertificateCreateWithData(NULL,(__bridge CFDataRef)der):NULL;identity=cert?SecIdentityCreate(NULL,cert,key):NULL;
  if(identity){NSFileManager *fm=NSFileManager.defaultManager;if(![fm createDirectoryAtPath:self.directory withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions:@0700} error:error]){CFRelease(identity);identity=NULL;}else{NSData *json=[NSJSONSerialization dataWithJSONObject:@{@"address":address,@"renewAt":@(NSDate.date.timeIntervalSince1970+80*86400),@"der":[der base64EncodedStringWithOptions:0]} options:0 error:error];if(!json||![json writeToFile:path options:NSDataWritingAtomic error:error]){CFRelease(identity);identity=NULL;}}}
 }
 if(cert)CFRelease(cert);CFRelease(key);if(!identity){if(error&&!*error)*error=TLSError(-6);return NO;}if(_identity)CFRelease(_identity);_identity=identity;self.certificate=der;
 uint8_t digest[CC_SHA256_DIGEST_LENGTH];CC_SHA256(der.bytes,(CC_LONG)der.length,digest);NSMutableArray *hex=[NSMutableArray new];for(NSUInteger i=0;i<sizeof(digest);i++)[hex addObject:[NSString stringWithFormat:@"%02X",digest[i]]];self.fingerprint=[hex componentsJoinedByString:@":"];return YES;
}
@end
